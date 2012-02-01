# Controller for all admin-level functions for features. Checks to see if the currently logged-in
# user is a staff member before allowing access

class Admin::FeaturesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


#SNIP=featured_products
# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature
	# Displays a list of Features for editing.
	#
	# <b>Template:</b> <tt>admin/features/list.rhtml</tt>
	def list
		@current_area = 'features'
		@current_menu = 'products'

		sort_order ||= get_sort_order("s-code", "products.product_code")
		sort_order ||= get_sort_order("s-name", "products.product_name")
# heh - doesn't work well when products are featured in multiple categories/static pages
#		sort_order ||= get_sort_order("s-category_static", [ "categories.name", "static_pages.name" ])
		sort_order ||= "products.product_code ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		if params[:query] and !params[:query].empty?
			@keywords = params[:query].split
			@query = @keywords.join(' ')
			mode = params[:mode] || 'all'
			where_parts = @keywords.collect { |k| "(products.product_code LIKE \"%#{k}%\" OR products.product_name LIKE \"%#{k}%\" OR products.description LIKE \"%#{k}%\" OR products.id=\"#{k}\")" }
			where_clause = where_parts.join(mode == 'all' ? ' AND ' : ' OR ')
		else
			where_clause = '1'
		end
		@features_count = Feature.count(where_clause, :include => [:product])

		@pages = Paginator.new(self, @features_count, items_per_page, page)

		if params[:delete] and params[:select]
			c = params[:select].keys.collect { |k| "id=#{k}" }.join(' OR ')
			Feature.delete_all c
			redirect_to :action => :list
		end

		@features = Feature.find(:all, :conditions => where_clause, :include => [:categories, :static_pages, :product], :order => sort_order, :offset => offset, :limit => items_per_page)
	end


	# Allows a new feature to be created
	#
	# <b>Template:</b> <tt>admin/features/new.rhtml</tt>
	def new
		@current_area = 'features'
		@current_menu = 'products'

		@feature_categories = Array.new
		@feature_static_pages = Array.new
		if params[:save]
			params[:feature][:until] = ffs_parse_date(params[:feature][:until])
			@feature = Feature.new(params[:feature])
			if @feature.save
				if params[:category] && params[:category][:id]
					params[:category][:id].each do |cur_cat|
						@feature.categories << Category.find(cur_cat.to_i)
					end
				end
				if params[:static_page] && params[:static_page][:id]
					params[:static_page][:id].each do |cur_stat|
						@feature.static_pages << StaticPage.find(cur_stat.to_i)
					end
				end

				@feature.save
				redirect_to(:action => :list) and return false
			end
		else
			@feature = Feature.new

			if params[:id]
				@feature[:product_id] = params[:id].to_i
			end
		end

		@products_by_category = Category.all.collect { |c| { :name => c.name, :id => c.id, :products => c.products } }
	end


	# Displays a Feature for editing. Also handles updating the Feature.
	#
	# <b>Template:</b> <tt>admin/features/edit.rhtml</tt>
	def edit
		@current_area = 'features'
		@current_menu = 'products'

		if params[:id]
			begin
				@feature = Feature.find(params[:id], :include => [ :product ])
			rescue ActiveRecord::RecordNotFound
				redirect_to(:action => list) and return false
			end

			if params[:save]
				params[:feature][:until] = ffs_parse_date(params[:feature][:until])
				if @feature.update_attributes params[:feature]
					if params[:category] && params[:category][:id]
						@feature.categories = []
						params[:category][:id].each do |cur_cat|
							@feature.categories << Category.find(cur_cat.to_i)
						end
					end
					if params[:static_page] && params[:static_page][:id]
						@feature.static_pages = []
						params[:static_page][:id].each do |cur_stat|
							@feature.static_pages << StaticPage.find(cur_stat.to_i)
						end
					end

					@feature.save
					redirect_to(:action => :list) and return false
				end
			end

			@feature_categories = Array.new
			@feature_static_pages = Array.new

			@feature.categories.each do |cur_cat|
				@feature_categories << cur_cat[:id]
			end
			@feature.static_pages.each do |cur_stat|
				@feature_static_pages << cur_stat[:id]
			end

			@products_by_category = Category.all.collect { |c| { :name => c.name, :id => c.id, :products => c.products } }
		else
			redirect_to(:action => list) and return false
		end
	end
# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
#/SNIP=featured_products
end
