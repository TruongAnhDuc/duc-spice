# Controller for all admin-level functions for categories. Checks to see if the currently logged-in
# user is a staff member before allowing access

class Admin::CategoriesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Displays the list of categories for editing. Also handles functions like deleting categories, or changing
	# their display order.
	#
	# <b>Template:</b> <tt>admin/categories/list.rhtml</tt>
	def list
		@current_area = 'categories'
		@current_menu = 'products'

		if params[:select]
			if params[:delete]
				# you MUST manually move child nodes in an acts_as_tree up before calling
				# the destroy! method. Otherwise Rails will automatically go and delete all
				# the child nodes even before the selected nodes' 'before_destroy' callback
				# is triggered!
				params[:select].keys.each do |k|
					the_cat = Category.find(k)
					the_cat.move_children_up()
					Category.destroy(the_cat.id)
				end
			elsif params[:move_up]
				# We have to use a Hash as Array iterators do not like sparse indexing.
				selected_categories = Hash.new
				cat_index = Hash.new
				params[:select].keys.each do |k|
					c = Category.find(k)
					if selected_categories[c.parent_id].nil?
						selected_categories[c.parent_id] = Hash.new
					end
					selected_categories[c.parent_id][c.id] = c.sequence
					cat_index[c.id] = c
				end
				selected_categories.each do |i, parent|
					# Hash.sort converts the hash into a nested array before sorting; [0] = key, [1] = value.
					# Note that we only want the IDs which are contained in the index 'j'.
					parent.sort{|a,b| (a[1]<=>b[1])}.each do |j, the_sequence|
						cat_index[j].move_higher
					end
				end
			elsif params[:move_down]
				# See comments for move_up above
				selected_categories = Hash.new
				cat_index = Hash.new
				params[:select].keys.each do |k|
					c = Category.find(k)
					if selected_categories[c.parent_id].nil?
						selected_categories[c.parent_id] = Hash.new
					end
					selected_categories[c.parent_id][c.id] = c.sequence
					cat_index[c.id] = c
				end
				selected_categories.each do |i, parent|
					# Note order of b/a is swapped to move down.  This and move_lower instead of move_higher
					# is the only difference between this and the move_up code above.
					parent.sort{|a,b| (b[1]<=>a[1])}.each do |j, the_sequence|
						cat_index[j].move_lower
					end
				end
			end
			expire_fragment(:controller => :products, :action => :home, :part => 'category_menu')
		end

		@root_cat = Category.find(1)
	end


	# Handles the creation of a new Category
	def new
		if params[:create]
			@root_category = Category.find(:first, :conditions => 'parent_id IS NULL') || Category.create
			params[:category][:parent_id] = @root_category.id unless !params[:category][:parent_id].empty?
			@category = Category.new(params[:category])
			if @category.save
				expire_fragment(:controller => :products, :action => :home, :part => 'category_menu')

				# Requested after a usability review so people can add the description and SEO options
				# without having to click through.  If you disagree with this then swap for the
				# commented-out code below.
				redirect_to(:action => :edit, :id => @category.id) and return true
#				flash.now[:notice] = 'Category successfully created'
			else
				flash.now[:notice] = 'Error creating category'
			end
		end

		redirect_to(:action => :list)
	end


	# Displays category details for editing.
	#
	# <b>Template:</b> <tt>admin/categories/edit.rhtml</tt>
	def edit
		@current_area = 'categories'
		@current_menu = 'products'

		@category = Category.find(params[:id])
		if params[:save]
			flash[:notice] = 'Saving'
			if @category.update_attributes(params[:category])
				flash[:notice] = 'Updated successfully'
				expire_fragment(:controller => :products, :action => :home, :part => 'category_menu')

				if @category.id == 1
					lines = Array.new
					found = false
					open("#{RAILS_ROOT}/config/routes.rb").each do |cur_line|
						if found
							found = false
							lines << "  map.connect '#{@category.filename}/*categories', :controller => 'products', :action => 'category'\n"
						else
							lines << cur_line
						end

						if cur_line =~ /^  #-PRODUCTS/
							found = true
						end
					end

					open("#{RAILS_ROOT}/config/routes.rb", "w") do |router|
						lines.each do |cur_line|
							router.write(cur_line)
						end
					end
				end

				redirect_to :action => :list
			else
				flash[:notice] = 'Update failed'
			end
		end
	end
end
