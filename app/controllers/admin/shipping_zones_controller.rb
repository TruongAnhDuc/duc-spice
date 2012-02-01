# Controller for all admin-level functions for shipping zones. Checks to see if the currently
# logged-in user is a client before allowing access

class Admin::ShippingZonesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_client
	helper :admin
	layout 'admin'


	# Displays a list of available ShippingZones, and handles editing on a global level (changing
	# display order, deleting, adding a new zone, and setting the default zone).
	#
	# <b>Template:</b> <tt>admin/shipping_zones/list.rhtml</tt>
	def list
		@current_area = 'zones'
		@current_menu = 'settings'

		if request.post?
			if params[:create]
				@new_zone = ShippingZone.new({ :name => params[:new_zone_name] })
				if !@new_zone.save
					flash.now[:notice] = 'Error: Could not create new shipping option.'
				end
			elsif params[:id]
				@zone = ShippingZone.find(params[:id])
				if params[:delete]
					@zone.destroy
				elsif params[:default]
					ShippingZone.update_all('default_zone = 0', 'default_zone <> 0')
					@zone.update_attribute(:default_zone, 1)
				elsif params[:move_up]
					@zone.move_higher
				elsif params[:move_down]
					@zone.move_lower
				end
			end
			redirect_to :action => :list
		else
			@shipping_zones = ShippingZone.find(:all, :include => :countries, :order => 'position')
		end
	end


	# Handles option editing for a particular shipping zone (adding/removing countries, changing
	# rates, etc). Called via AJAX from the main Shipping Zone page.
	#
	# <b>Template:</b> <tt>admin/shipping_zones/_editor.rhtml</tt>
	def edit
		@current_area = 'zones'
		@current_menu = 'settings'

		@zone = ShippingZone.find(params[:id])
		countries_in_zone = @zone.countries.collect { |country| country.name }
		country_list = Country.countries

		@zone.update_attributes({
			:name => params[:name],
			:per_item => params[:per_item],
			:flat_rate => params[:flat_rate],
			:formula => params[:formula],
			:formula_description => params[:formula_description]
		})


		#SNIP=weight_based_shipping
		# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature

		@zone.update_attributes({
			:per_kg => params[:per_kg],
		})

		# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
		#/SNIP=weight_based_shipping


		# Convert the country parameters into what's recorded in the database... /sigh/
		if params[:include]
			params[:include].each_index do |i|
				params[:include][i] = country_list[params[:include][i]]
			end
		end

		# Delete all countries in this zone that are no longer included in this zone.
		countries_in_zone.each do |country|
			if params[:include].nil? or params[:include].index(country).nil?
				@zone.countries.delete(Country.find_by_name(country))
			end
		end
		# Add in the ones that aren't already there.
		if params[:include]
			params[:include].each do |country|
				if countries_in_zone.index(country).nil?
					@zone.countries.create({ :name => country })
				end
			end
		end
		# The others were already there and still need to be there, so we can ignore them.

		render :partial => 'editor'
	end
end
