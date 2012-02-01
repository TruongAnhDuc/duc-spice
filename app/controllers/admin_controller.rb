require 'spreadsheet/excel'
include Spreadsheet

# Controller for all admin-level functions, available at http://www.yourdomain.tld/admin/.
# Checks to see if the currently logged-in user is a staff member before allowing access.

class AdminController < ApplicationController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff, :except => :login
	before_filter :require_authorisation_client, :only => [ :shipping_zones, :edit_zone ]


	# Dynamically creates methods that allow you to check if the current user passes a given
	# level of authorisation
	User.list_levels.each do |cur_level|
		method_name = 'require_authorisation_' + cur_level.to_s

		define_method(method_name) do
			if !session[:user_id] || @current_user.permissions < cur_level
				session[:jump_to] = request.parameters
				redirect_to(:controller => "/admin", :action => :login) and return false
			end
		end
	end


	# Returns a sort-string (in SQL) based on the given GET parameter and table column to sort on
	def get_sort_order (get_param, column_name)
		if params[get_param] && !params[get_param].empty?
			if params[get_param].downcase == "asc"
				if column_name.kind_of?(Array)
					"#{column_name.join(' ASC, ')} ASC"
				else
					"#{column_name} ASC"
				end
			else
				if column_name.kind_of?(Array)
					"#{column_name.join(' DESC, ')} DESC"
				else
					"#{column_name} DESC"
				end
			end
		end
	end


	def defaults
		# "Demonstration" admins have restricted abilities: this was implemented for rocketcart.avatar.co.nz
		# so people can poke around the admin area without breaking things too badly (eg changing settings,
		# accessing our payment gateway keys).
		if @current_user
			# This is mostly duplicated in customer_report (except for the last conditional)
			@demo_admin = !(!@configurator[:demo] or !@configurator[:demo][:enabled] or !@configurator[:demo][:enabled][:value] or (@current_user.email != @configurator[:demo][:user][:value]))
		end

#		@pending_orders = (x = Order.count("status='awaiting_shipping'" )).zero? ? '' : " (#{x})"
		@pending_orders = ''
	end


	def index
	end


	# Admin login action. Generates a login page.
	#
	# <b>Template:</b> <tt>admin/login.rhtml</tt>
	def login
		@user = @current_user || User.new
		# If logged in, redirect to the pending orders page.  This only happens if we didn't jump_to
		# something in require_authorisation: it's pretty confusing if you get the login screen again
		# _after_ you successfully logged in!
		if @user.permissions >= :client
			redirect_to(:controller => 'admin/orders', :action=> 'pending') and return false
		end
	end


	# Displays a list of products for editing. Also handles deleting/undeleting products, and bulk-adding products to categories.
	#
	# <b>Template:</b> <tt>admin/products.rhtml</tt>
	def products
		@current_area = 'products'
		@current_menu = 'products'

		sort_order ||= get_sort_order("s-code", "product_code")
		sort_order ||= get_sort_order("s-name", "product_name")
		sort_order ||= "product_name ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		if params[:query] and !params[:query].empty?
			@keywords = params[:query].split
			@query = @keywords.join(' ')
			mode = params[:mode] || 'all'
			where_parts = @keywords.collect { |k| "(product_code LIKE '%#{k}%' OR product_name LIKE '%#{k}%' OR description LIKE '%#{k}%' OR id='#{k}')" }
			where_clause = where_parts.join(mode == 'all' ? ' AND ' : ' OR ')
		else
			where_clause = '1'
		end
		@product_count = Product.count('available=1 AND ' + where_clause)

		@pages = Paginator.new(self, @product_count, items_per_page, page)

		if params[:delete] and params[:select]
			c = params[:select].keys.collect { |k| "id=#{k}" }.join(' OR ')
			Product.update_all 'available=0', c
			redirect_to :action => :products
		end

		if params[:add_to]
			if params[:select]
				c = Category.find(params[:category_id])
				Product.find(:all, :conditions => params[:select].keys.collect { |k| "id=#{k}" }.join(' OR ')).each do |p|
					# don't crash with a MySQL "duplicate key" error if the product already belongs to the selected category
					if !p.categories.index(c)
						p.categories << c
					end
				end
			else
				redirect_to :action => :new, :category_id => params[:category_id]
			end
		end

		@products = Product.find(:all, :conditions => 'available=1 AND ' + where_clause, :order => sort_order, :offset => offset, :limit => items_per_page)
	end


	# Displays a list of deleted products. Also handles undeleting products.
	#
	# <b>Template:</b> <tt>admin/deleted_products.rhtml</tt>
	def deleted_products
		@current_area = 'deleted_products'
		@current_menu = 'products'

		sort_order ||= get_sort_order("s-code", "product_code")
		sort_order ||= get_sort_order("s-name", "product_name")
		sort_order ||= "product_name ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		if params[:query] and !params[:query].empty?
			@keywords = params[:query].split
			@query = @keywords.join(' ')
			mode = params[:mode] || 'all'
			where_parts = @keywords.collect { |k| "(product_code LIKE '%#{k}%' OR product_name LIKE '%#{k}%' OR description LIKE '%#{k}%' OR id='#{k}')" }
			where_clause = where_parts.join(mode == 'all' ? ' AND ' : ' OR ')
		else
			where_clause = '1'
		end
		@product_count = Product.count('available=0 AND ' + where_clause)

		@pages = Paginator.new(self, @product_count, items_per_page, page)

		if params[:undelete] and params[:select]
			c = params[:select].keys.collect { |k| "id=#{k}" }.join(' OR ')
			Product.update_all 'available=1', c
			redirect_to :action => :deleted_products
		end

		@products = Product.find(:all, :conditions => 'available=0 AND ' + where_clause, :order => sort_order, :offset => offset, :limit => items_per_page)
	end


	# Form for creating a new product. The actual work of creating a product is done by +create+.
	#
	# New:
	# Creates a new product. Redirects to +product#options+ on success so the options can be set.
	#
	# <b>Templates:</b> <tt>admin/new.rhtml</tt>, <tt>admin/_product_form.rhtml</tt>
	def new
		@current_area = 'products'
		if request.post?
			@current_menu = 'products'

			if params[:product][:categories]
				product_categories = params[:product][:categories].map { |c| Category.find(c.to_i) }
			else
				product_categories = []
			end
			params[:product][:categories] = []
			params[:product][:expiry_date] = ffs_parse_date(params[:product][:expiry_date])
			@product = Product.new(params[:product])
			if @product.save
				@product.categories = product_categories

				if params[:image] and params[:image][:image]
					# != '' works, but .empty? doesn't - .empty? isn't defined for IOString's :x
					if params[:image][:image] != ''
						if params[:image][:image].original_filename
							if !params[:image][:image].original_filename.empty?
								@product.image ||= Image.new
								@product.image.image = params[:image][:image]
								@product.image.save
							end
						end
					end
				end

				if params[:product][:product_type_id].to_i > 0
					the_product_type = ProductType.find(params[:product][:product_type_id])
				end

				if the_product_type
					the_product_type.quirks.each do |cur_quirk|
						quirk_value = QuirkValue.new({ :product_id => @product[:id], :quirk_id => cur_quirk[:id], :value => params[:quirk][cur_quirk[:id].to_s] })
						quirk_value.save

						if cur_quirk[:required] && (!params[:quirk][cur_quirk[:id].to_s] || params[:quirk][cur_quirk[:id].to_s].empty?)
							@product.errors.add "product_type_id", " #{the_product_type[:name]} is missing the #{cur_quirk[:name]} attribute"
						end
					end
				end

				flash[:notice] = 'Product successfully created'
				redirect_to :action => :product, :id => @product.id, :anchor => 'options'
			end

			@product.categories = product_categories
		else
			@current_menu = 'products'

			@product = Product.new
			@image = Image.new
			@category_id = params[:category_id]
		end

		all_product_types = ProductType.find(:all)

		@product_types = Array.new
		@quirks = Hash.new

		@product_types << [0, "(none)"]
		all_product_types.each do |cur_product_type|
			@product_types << [cur_product_type.id, cur_product_type.to_s]

			if !@quirks.has_key?(cur_product_type.id)
				@quirks[cur_product_type.id] = Hash.new
			end

			cur_product_type.quirks.each do |cur_quirk|
				if !@quirks[cur_product_type.id].has_key?(cur_quirk.id)
					@quirks[cur_product_type.id][cur_quirk.id] = Hash.new
				end

				@quirks[cur_product_type.id][cur_quirk.id]["name"] = cur_quirk[:name]
				@quirks[cur_product_type.id][cur_quirk.id]["type"] = cur_quirk[:type]
				@quirks[cur_product_type.id][cur_quirk.id]["required"] = cur_quirk[:required]
			end
		end
	end


	# Displays a product for editing.
	#
	# <b>Templates:</b> <tt>admin/product.rhtml</tt>, <tt>admin/_product_form.rhtml</tt>
	def product
		@current_area = 'products'
		@current_menu = 'products'

		if params[:save]
			@product = Product.find(params[:id])

			if params[:delete_image]
				Image.delete(@product.image.id)
				return false # we don't need to process anything more
			end

			if params[:product][:categories]
				params[:product][:categories].map! { |c| Category.find(c.to_i) }
			else
				params[:product][:categories] = []
			end
			params[:product][:expiry_date] = ffs_parse_date(params[:product][:expiry_date])
			if params[:image] and params[:image][:image]
				if @product.image
					Thumbnail.delete_all("product_id=#{@product.id}")
				end

				# != '' works, but .empty? doesn't - .empty? isn't defined for IOString's :x
				if params[:image][:image] != ''
					if params[:image][:image].original_filename
						if !params[:image][:image].original_filename.empty?
							@product.image ||= Image.new
							@product.image.image = params[:image][:image]
							@product.image.save
						end
					end
				end
			end

			if params[:product][:product_type_id].to_i != @product[:product_type_id]
				@product.quirk_values.each do |old_quirk_value|
					QuirkValue.delete(old_quirk_value[:id])
				end
			end

			if @product.update_attributes(params[:product])
				if params[:product][:product_type_id] && params[:product][:product_type_id].to_i > 0
					the_product_type = ProductType.find(params[:product][:product_type_id])

					if the_product_type
						the_product_type.quirks.each do |cur_quirk|
							edit = false
							@product.quirk_values.each do |cur_quirk_value|
								if cur_quirk_value[:quirk_id] == cur_quirk[:id]
									edit = true
									cur_quirk_value[:value] = params[:quirk][cur_quirk[:id].to_s]
									cur_quirk_value.save
								end
							end

							unless edit
								quirk_value = QuirkValue.new({ :product_id => @product[:id], :quirk_id => cur_quirk[:id], :value => params[:quirk][cur_quirk[:id].to_s] })
								quirk_value.save
							end

							if cur_quirk[:required] && (!params[:quirk][cur_quirk[:id].to_s] || params[:quirk][cur_quirk[:id].to_s].empty?)
								@product.errors.add "product_type_id", " #{the_product_type[:name]} is missing the #{cur_quirk[:name]} attribute"
							end
						end
					end
				end

				if (@product.errors.empty?)
					redirect_to :action => :products and return true
				end
			end
		else
			@product = Product.find(params[:id], :include => [ :categories, :quirk_values ])
			@image = @product.image || Image.new
		end

		all_product_types = ProductType.find(:all)

		@product_types = Array.new
		@quirks = Hash.new

		@product_types << [0, "(none)"]
		all_product_types.each do |cur_product_type|
			@product_types << [cur_product_type.id, cur_product_type.to_s]

			if !@quirks.has_key?(cur_product_type[:id])
				@quirks[cur_product_type[:id]] = Hash.new
			end

			cur_product_type.quirks.each do |cur_quirk|
				if !@quirks[cur_product_type[:id]].has_key?(cur_quirk[:id])
					@quirks[cur_product_type[:id]][cur_quirk[:id]] = Hash.new
				end

				@quirks[cur_product_type[:id]][cur_quirk[:id]]["name"] = cur_quirk[:name]
				@quirks[cur_product_type[:id]][cur_quirk[:id]]["type"] = cur_quirk[:type]
				@quirks[cur_product_type[:id]][cur_quirk[:id]]["required"] = cur_quirk[:required]

				@product.quirk_values.each do |cur_quirk_value|
					if cur_quirk_value[:quirk_id] == cur_quirk[:id]
						@quirks[cur_product_type[:id]][cur_quirk[:id]]["value"] = cur_quirk_value[:value]
					end
				end
			end
		end

		# create the 'option_values' array, which is an array  (indexed by Option id) of
		# OptionValue's that this Product uses. The Product will incur a single DB hit (better
		# than before) for its possible OptionValue's, as well as the DB hit to get the Product
		product_option_values = @product.product_option_values

		@option_values = Array.new
		product_option_values.each do |cur_product_option_value|
			begin
				cur_option_value = OptionValue.find(cur_product_option_value[:option_value_id])
			rescue ActiveRecord::RecordNotFound
				logger.error("Invalid OptionValue for product \##{@product.id} - was given \##{cur_product_option_value[:option_value_id]}")
			else
				if !@option_values[cur_option_value[:option_id]]
					@option_values[cur_option_value[:option_id]] = Array.new
				end
				@option_values[cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
			end
		end

		@used_options = Array.new
		@free_options = Array.new
		Option.find(:all).each do |cur_option|
			found = false
			product_option_values.each do |cur_product_option_value|
				cur_option_value = OptionValue.find(cur_product_option_value[:option_value_id])
				if cur_option_value[:option_id] == cur_option.id
					found = true
					if !@used_options.include?(cur_option)
						@used_options << cur_option
					end
				end
			end
			unless found
				@free_options << cur_option
			end
		end
	end


	# Adds an option to a product and redirects to the product's details page.
	def add_option
		@current_menu = 'products'

		if params[:option_id]
			@product = Product.find(params[:id])
			cur_option = Option.find(params[:option_id])
			option_values = OptionValue.find(:all, :conditions => [ "option_id = #{cur_option[:id]}" ])

			option_values.each do |cur_option_value|
				cur_default_value = cur_option[:default_value] == cur_option_value[:id].to_s ? 1 : 0
				@product.product_option_values.create({ :option_value_id => cur_option_value[:id], :position => cur_option_value[:position], :default_value => cur_default_value })
			end


		end

		redirect_to :action => :product, :id => @product.id, :anchor => 'options'
	end


	# Updates a product's options and redirects to the product's details page.
	def update_options
		@current_menu = 'products'

		@product = Product.find(params[:id])

		if params[:hide_option_value]
			cur_option_value = nil
			params[:hide_option_value].each_key do |cur_option_value_id|
				cur_option_value = OptionValue.find(cur_option_value_id)
			end
			ProductOptionValue.delete_all([ "product_id = #{@product.id} AND option_value_id = #{cur_option_value.id}" ])
		elsif params[:show_option_value]
			cur_option_value = nil
			params[:show_option_value].each_key do |cur_option_value_id|
				cur_option_value = OptionValue.find(cur_option_value_id)
			end
			cur_default = (cur_option_value.option[:default_value] == cur_option_value[:id].to_s) ? 1 : 0
			@product.product_option_values.create(:option_value_id => cur_option_value[:id], :position => cur_option_value[:position], :default_value => cur_default)
		elsif params[:remove]
			option_values = OptionValue.find(:all, :conditions => [ "option_id = #{params[:option_id]}" ])
			option_values.each do |cur_option_value|
				ProductOptionValue.delete_all([ "product_id = #{@product.id} AND option_value_id = #{cur_option_value.id}" ])
			end
		end

		redirect_to :action => :product, :id => @product.id, :anchor => 'options'
	end


	def show_detailed_version
		render :partial => 'show_detailed_version'
	end
end
