# Controller for all admin-level functions for options on products. Checks to see if the currently
# logged-in user is a staff member before allowing access

class Admin::OptionsController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Displays a list of available Product Options.
	#
	# <b>Templates:</b> <tt>admin/options/list.rhtml</tt>, <tt>admin/_option_editor.rhtml</tt>
	def list
		@current_area = 'options'
		@current_menu = 'products'

		if params[:delete] and params[:select]
			Option.delete(params[:select].keys)
			redirect_to :action => :list
		end

		@options = Option.find(:all)
	end


	# Creates a new Product Option
	def new
		if params[:create]
			@option = Option.create_option(params[:option])
			if @option.save
				if params[:option][:type] == 'TextOption'
					@option.values.create({ :value => '' })
				elsif params[:option][:type] == 'CheckBox'
					@option.values.create({ :value => 'yes' })
				end
				flash.now[:notice] = 'Option successfully created'
			else
				@option = nil
				flash.now[:notice] = 'Error creating option'
			end
		else
			@option = nil
		end

		redirect_to :action => :list
	end


	# Deletes an option and redirects to the options list.
	def delete
		@current_menu = 'products'

		# have to delete the OptionValue's first (fixed)
		OptionValue.delete_all([ "option_id = #{params[:id]}" ])
		Option.delete(params[:id])

		redirect_to :action => :list
	end


	# Displays an option for editing.
	#
	# <b>Templates:</b> <tt>admin/options/edit.rhtml</tt>, <tt>admin/_option_editor.rhtml</tt>
	def edit
		@current_area = 'options'
		@current_menu = 'products'

		@option = Option.find(params[:id])
	end


	# Renders a preview of an option.
	#
	# <b>Template:</b> <tt>admin/options/_option_preview.rhtml</tt>
	def preview
		@current_area = 'options'
		@current_menu = 'products'

		@option = Option.find(params[:id])
		render :partial => 'preview', :option => @option
	end


	# Renders an editing GUI for an option. This is called via AJAX from the main Options page.
	#
	# <b>Template:</b> <tt>admin/options/_option_editor.rhtml</tt>
	def editor
		@option = Option.find(params[:id])

		if params[:do] == 'save'
			@option.name = params[:name]
			@option.comment = params[:comment]
			@option.save

			@option.values.each do |cur_value|
				cur_value.value = params[('value-' + cur_value.id.to_s).to_sym]
				cur_value.extra_cost = params[('extra-cost-' + cur_value.id.to_s).to_sym]
				cur_value.wholesale_extra_cost = params[('wholesale-extra-cost-' + cur_value.id.to_s).to_sym]
				cur_value.wholesale_only = (params[('wholesale-only-' + cur_value.id.to_s).to_sym].to_i == 1)
				cur_value.extra_weight = params[('extra-weight-' + cur_value.id.to_s).to_sym]
				if !cur_value.value.gsub(/\s/, '').empty? # Don't allow empty option-value name
					cur_value.save
				end
			end
		elsif params[:do] == 'set_default'
			if params[:values]
				@option.set_default(params[:values])
			elsif params[:option] && params[:option][params[:id]]
				@option.set_default(params[:option][params[:id]])
			else # setting default to nothing
				@option.set_default nil
			end
			@option.save
		elsif params[:do] == 'add'
			cur_value = OptionValue.new
			cur_value.value = params[:new_value]
			cur_value.extra_cost = params[:new_extra_cost].empty? ? 0 : params[:new_extra_cost]
			cur_value.wholesale_extra_cost = params[:new_wholesale_extra_cost].empty? ? 0 : params[:new_wholesale_extra_cost]
			cur_value.wholesale_only = (params[:new_wholesale_only].to_i == 1)
			cur_value.extra_weight = params[:new_extra_weight].empty? ? 0 : params[:new_extra_weight]
			if !cur_value.value.gsub(/\s/, '').empty?
				@option.values << cur_value
				@option.save
			end
		elsif params[:do] == 'delete_value'
			# We need to manually delete the relevant ProductOptionValues otherwise the table will be left with
			# orphaned references.  If we don't do this we get crashes in the product editor...
			params[:values].each do |cur_value|
				ProductOptionValue.delete_all(:option_value_id => cur_value)
			end
			@option.configure_with params
			@option.save
		else # This covers any other actions, eg reordering option values
			@option.configure_with params
			@option.save
		end

		# wasn't always refreshing properly after configure_with, so forcing a refresh here.
		@option = Option.find(params[:id])

		render :partial => 'editor', :option => @option, :locals => { :show_saved_text => (params[:do] == 'save') }
	end
end
