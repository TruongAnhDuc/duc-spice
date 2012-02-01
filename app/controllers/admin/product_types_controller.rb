# Controller for all admin-level functions for product types. Checks to see if the currently logged
# -in user is a client before allowing access

class Admin::ProductTypesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Displays a list of available Product Types, with an option to create a new one.
	#
	# <b>Templates:</b> <tt>admin/product_types/list.rhtml</tt>,
	# <tt>admin/_product_type_editor.rhtml</tt>
	def list
		@current_area = 'product_types'
		@current_menu = 'products'

		if params[:delete] and params[:select]
			ProductType.delete(params[:select].keys)
			redirect_to :action => :list
		end

		@product_types = ProductType.find(:all)
	end


	# Deletes a Product Type and redirects to the Product Types list.
	def delete
		@current_menu = 'products'

		# have to delete the Quirk's and their QuirkValues first
		Quirk.find_all().each do |cur_quirk|
			QuirkValue.delete_all([ "quirk_id = #{cur_quirk[:id]}" ])
			Quirk.delete(cur_quirk[:id])
		end

		# also need to de-couple any Product's that were this type
		products = Product.find(:all, :conditions => [ "product_type_id = #{params[:id]}" ])
		products.each do |cur_product|
			cur_product["product_type_id"] = 0
			cur_product.save
		end

		ProductType.delete(params[:id])

		redirect_to :action => :list
	end


	# Creates a new Product Type and redirects to the Product Types list.
	def new
		@current_menu = 'products'

		@product_type = ProductType.new({ :name => params[:product_type][:name] })
		@product_type.save

		redirect_to :action => :list
	end


	# Renders an editing GUI for a Product Type. This is probably called via AJAX from the main
	# Product Types page.
	#
	# <b>Template:</b> <tt>admin/product_types/_product_type_editor.rhtml</tt>
	def editor
		@current_area = "product_types"
		@product_type = ProductType.find(params[:id])
		@current_menu = "products"

		if params[:do] == "save"
			@product_type.name = params[:name]
			@product_type.save

			@product_type.quirks.each do |cur_quirk|
				cur_quirk.name = params[("name-#{cur_quirk.id.to_s}").to_sym]
				cur_quirk.required = params[("required-#{cur_quirk.id.to_s}").to_sym] == "yes" ? true : false

				if !cur_quirk.name.gsub(/\s/, "").empty? # Don't allow empty product-type name
					cur_quirk.save
				end
			end
		elsif params[:do] == "add"
			quirk_class = (Object.subclasses_of(Quirk).select { |k| k.to_s == "#{params[:new_type].capitalize}Quirk" }).first

			new_quirk = quirk_class.new({
				:name => params[:new_name],
				:required => (params[:new_required] == "yes" ? true : false)
			})
			new_quirk[:product_type_id] = @product_type[:id]
			new_quirk.save
		elsif params[:do] == "up"
			params[:values].each do |cur_id|
				Quirk.find(cur_id).move_higher
			end
		elsif params[:do] == "down"
			params[:values].each do |cur_id|
				Quirk.find(cur_id).move_lower
			end
		elsif params[:do] == "delete_attribute"
			params[:values].each do |cur_id|
				QuirkValue.delete_all([ "quirk_id = #{cur_id}" ])
			end
			Quirk.delete(params[:values])
		end

		# wasn't always refreshing properly after move_higher/move_lower, so forcing a refresh
		@product_type = ProductType.find(params[:id])

		render :partial => "editor", :option => @product_type, :locals => { :show_saved_text => (params[:do] == "save") }
	end
end
