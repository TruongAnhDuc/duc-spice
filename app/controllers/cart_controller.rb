# Contains actions and functions for managing the commerce part of the site:
# * Viewing and editing your cart
# * Checking out
# * Paying for your order
#
# ...and many more favourites!
#
# <b>Todo:</b>
# * Build some sort of "my details" editor.
class CartController < ApplicationController
	# Use the main site layout for cart functions too
	layout 'products', :except => [ :cart_summary,  :cart_summary_brief, :convert_prices, :convert_prices_cart ]

	# Require the user to be registered and logged in before checking out.
	before_filter :authorise
	before_filter :require_authorisation_user, :only => :checkout


	def require_authorisation_user
		if !session[:user_id] || @current_user.permissions < :user
			session[:jump_to] = request.parameters
			redirect_to(:action => :login) and return false
		end
	end

#	User.list_levels.each do |cur_level|
#		define_method(('require_authorisation_' + cur_level.to_s).to_sym) do
#			if !session[:user_id] || @current_user.permissions < cur_level
#				session[:jump_to] = request.parameters
#				redirect_to(:action => :login) and return false
#			end
#		end
#	end


	# a quick redirect in case people type in /cart/
	def index
		redirect_to :action => :show
	end


	# View the contents of your cart.
	#
	# <b>Templates:</b> <tt>cart/show.rhtml</tt>, <tt>cart/cart_form.html</tt>
	def show
		@cart = find_cart


		@multiplier = 1.0
		if @cart.priced and @cart.priced == 0
			@multiplier = 1.1
		end

		@items = @cart.items

		# should really put some conditions in here so only Option's that are used in the Items
		# in the cart are included.
		@options = Option.find(:all)

		# create the 'option_values' array, which is an array (indexed by Product id) of arrays
		# (indexed by Option id) of OptionValue's. Each LineItem will incur a single DB hit
		# (better than before) for its possible OptionValue's, as well as the DB hit to get all
		# the LineItem's, and all the Option's.
		the_option_values = OptionValue.find(:all)

		@option_values = Array.new
		@items.each do |cur_item|
			@option_values[cur_item.product.id] = Array.new

			product_option_values = cur_item.product.product_option_values
			product_option_values.each do |cur_product_option_value|
				cur_option_value = false
				the_option_values.each do |cur_o_v|
					if cur_o_v[:id] == cur_product_option_value[:option_value_id]
						cur_option_value = cur_o_v
					end
				end

				if cur_option_value
					if !@option_values[cur_item.product.id][cur_option_value[:option_id]]
						@option_values[cur_item.product.id][cur_option_value[:option_id]] = Array.new
					end
					@option_values[cur_item.product.id][cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
				end
			end
		end
	end



	# Add a product to your cart. Usually called via AJAX: displays the results in
	# the "cart summary" part of the main site template.
	#
	# This function is smart enough to know if you've already got the item in your cart,
	# in which case it will just increment the quantity &mdash; unless the new product has
	# different options from what's already there.
	def add
		@product = Product.find(params[:id])
		@quantity = params[:quantity] || 1
		@cart = find_cart

		option_values = []

		if params[:option]
			params[:option].each_pair do |cur_index, cur_option_value|
				if cur_option_value.kind_of?(Array)
					cur_option_value.each do |cur_o_v|
						if cur_o_v and cur_o_v.to_i > 0
							option_values << cur_o_v
						end
					end
				else
					option_values << cur_option_value
				end
#				k = k.to_i
#				option_values[k] = Option.unscramble(v)
			end
		end
		@cart.add_product(@product, @quantity, option_values)

		if request.xml_http_request?
			render :action => @configurator[:modules][:cart_summary_template][:value], :layout => false
		else
			redirect_to :action => :show
		end
	end


	# Updates a user's cart, with quantities, options and so forth. Redirects to the checkout if
	# the user has pushed the "Checkout" button, or goes back to the cart editor otherwise.
	def update
		@cart = find_cart
		if params[:qty]
			params[:qty].each_pair do |i, q|
				if q.match(/^[0-9]+$/)
					@cart.items[i.to_i].quantity = q.to_i
				end
			end
		end

		if params[:option]
			params[:option].each_pair do |item_i, option|
				@cart.items[item_i.to_i].clear_options

				option.each_pair do |option_i, option_value|
					o_v = OptionValue.find(option_value.to_i)
					@cart.items[item_i.to_i].set_option(o_v)
				end
			end
		end

		if params[:delete] && params[:select]
			params[:select].keys.each do |k|
				@cart.items[k.to_i].quantity = 0
			end
		end

		@cart.delete_product(@cart.items.select { |i| i.quantity.zero? })

		if params[:checkout]
			redirect_to :action => :checkout
		else
			redirect_to :action => :show
		end
	end


	# Renders a mini-summary of what's in your cart, for AJAX display in the sidebar of the main
	# site template.
	#
	# <b>Template:</b> <tt>cart/cart_summary.rhtml</tt>
	def cart_summary
		@cart = find_cart
	end


	# Renders an even more mini mini-summary of what's in your cart, for AJAX display in the
	# sidebar of the main site template.
	#
	# <b>Template:</b> <tt>cart/cart_summary_brief.rhtml</tt>
	def cart_summary_brief
		@cart = find_cart
	end


	# Puts the "commerce" in e-commerce. Checks to make sure the user is actually trying to buy
	# things, then collects their shipping details and redirects them to the payment gateway.
	# Creates an Order in the database using the objects currently in the Cart.
	#
	# <b>Templates:</b> <tt>cart/checkout.rhtml</tt>, <tt>cart/_checkout_summary.rhtml</tt>
	def checkout
		@cart = find_cart

		@multiplier = 1.0
		if @cart.priced and @cart.priced == 0
			@multiplier = 1.1
		end

		if @cart.is_empty?
			redirect_to :action => :show
		else
			@items = @cart.items

			# so prices always appear in NZD
			@currency = Currency.find(:first)

			# should really put some conditions in here so only Option's that are used in the Items
			# in the cart are included.
			@options = Option.find(:all)

			# create the 'option_values' array, which is an array (indexed by Product id) of arrays
			# (indexed by Option id) of OptionValue's. Each LineItem will incur a single DB hit
			# (better than before) for its possible OptionValue's, as well as the DB hit to get all
			# the LineItem's, and all the Option's.
			@option_values = Array.new
			@items.each do |cur_item|
				@option_values[cur_item.product.id] = Array.new

				product_option_values = cur_item.product.product_option_values
				product_option_values.each do |cur_product_option_value|
					cur_option_value = OptionValue.find(cur_product_option_value[:option_value_id])
					if !@option_values[cur_item.product.id][cur_option_value[:option_id]]
						@option_values[cur_item.product.id][cur_option_value[:option_id]] = Array.new
					end
					@option_values[cur_item.product.id][cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
				end
			end

			@delivery_address_wanted = false

			if @current_user[:sees_wholesale]
				@first_wholesale_order = true

				old_wholesale_order = @current_user.orders.find(:first, :conditions => [ "wholesale=true AND status != 'in_progress' AND status != 'draft'" ])

				if old_wholesale_order && old_wholesale_order.class.to_s == "Order"
					@first_wholesale_order = false
				end
			end

			if params[:order]
				old_order = @current_user.orders.find(:first, :conditions => [ "status='in_progress'" ])

				@order = Order.new

				@order.priced = 1
				if @cart.priced and @cart.priced == 0
					@order.priced = 0
				end

				if old_order
					@order.billing_address = old_order.billing_address
					if old_order.delivery_address
						@order.delivery_address = old_order.delivery_address
					end
					@order.user = old_order.user
					@order.shipping_zone = old_order.shipping_zone
				end

				@order.update_attributes(params[:order])
				# for some reason the above doesn't save params[:order][:shipping_zone_id]!
				# so we'll force it...
				# I'm guessing this is something to do with the form item needing to be
				# something like params[:order][:shipping_zone] - really needs to be tested
				# though.
				if params[:order][:shipping_zone_id] and ShippingZone.find(params[:order][:shipping_zone_id])
					@order.shipping_zone = ShippingZone.find(params[:order][:shipping_zone_id])
				else
					@order.shipping_zone = nil
				end

				@delivery_address_wanted = params[:delivery_chooser_button].length >= 2

				# update billing address
				if @order.billing_address
					@order.billing_address.update_attributes(params[:billing_address])
				else
					@order.billing_address = Address.new(params[:billing_address])
				end

				# update delivery address if the option is required
				if @configurator[:modules][:separate_delivery_address] && @configurator[:modules][:separate_delivery_address][:value]
					if params[:delivery_chooser_button].length < 2
						if @order.delivery_address
							@order.delivery_address.destroy #RRAGGGH!
							# (hulk smash?)
						end
					else
						if @order.delivery_address
							@order.delivery_address.update_attributes(params[:delivery_address])
						else
							@order.delivery_address = Address.new(params[:delivery_address])
						end
					end
					@delivery_address = @order.delivery_address
				end
				@billing_address = @order.billing_address

				if params[:continue]
					@order.items << @items

					# this is problematic. For some reason, there are cases where
					# @order.items != @cart.items, and so the @order.total/subtotal is
					# being set too low
					#
					#@subtotal = @order.subtotal = @cart.subtotal
					@subtotal = @order.subtotal
					@shipping_cost = @order.shipping_cost = @cart.shipping_cost(@order.shipping_zone || ShippingZone.default_zone)
					@total = @order.total

					if @current_user[:sees_wholesale]
						@order.wholesale = true
					end

					@order.user = @current_user
					if @order.save
						@order.items.each do |item|
							item.save
						end
						unless @order.billing_address.save
							flash[:notice] = 'Please fill in all of the information required.'
							render :action => :checkout and return false
						end
						# The param appears as "delivery_chooser_button"=>["1"]
						if @order.delivery_address && (params[:delivery_chooser_button][0] == "1")
							unless @order.delivery_address.save
								flash[:notice] = 'Please fill in all of the information required.'
								render :action => :checkout and return false
							end
						end
						# Statically save total/subtotal to the DB for the payment gateway
						@order[:total] = @order.total
						@order[:subtotal] = @order.subtotal
						@order.save

						if params[:newsletter] && params[:newsletter] == 'newsletter'
							signup = NewsletterSignup.new({ :email => @current_user[:email], :first_name => @current_user[:first_name], :last_name => @current_user[:last_name] })
							signup.save
						end

						if @current_user[:sees_wholesale] && !@first_wholesale_order
							@order[:status] = "awaiting_shipping"
							@order.save
							redirect_to :action => :order_complete, :id => @order.id
						else
							redirect_to :action => :payment_gateway, :id => @order.id
						end
					else
						use_billing_address = true
						if @configurator[:application][:separate_delivery_address] && @configurator[:application][:separate_delivery_address][:value]
							unless params[:delivery_address].country.empty?
								use_billing_address = false
								if @configurator[:application][:show_country] == 'yes'
									@shipping_zones = ShippingZone.zones_for(@order.delivery_address.country)
								else
									@shipping_zones = ShippingZone.find(:all)
								end
							end
						end
						if use_billing_address
							if @configurator[:application][:show_country] == 'yes'
								@shipping_zones = ShippingZone.zones_for(@order.billing_address.country)
							else
								@shipping_zones = ShippingZone.find(:all)
							end
						end

						@shipping_zone = @order.shipping_zone || @shipping_zones.first
					end
				end
			else
				# BUGFIX! If a user hits the back button to get here, this will create a
				# new order. We need to check if the user has an in-progress order - if so,
				# then load that
				old_order = @current_user.orders.find(:first, :conditions => [ "status='in_progress'" ])
				if old_order
					@order = old_order
				else
					@order = Order.new({ :user => @current_user })
				end

				@most_recent_order = @current_user.orders.find(:first, :order => 'created_at DESC')
				if !@most_recent_order.nil?
					@billing_address = @most_recent_order.billing_address

					if @configurator[:modules][:separate_delivery_address] && @configurator[:modules][:separate_delivery_address][:value]
						if @most_recent_order.delivery_address
							@delivery_address = @most_recent_order.delivery_address
						else
							@delivery_address = Address.new({ :country => 'New Zealand' })
						end
					end
				else
					@order.shipping_email = @current_user.email
					@billing_address = Address.new({ :name => @current_user.to_s, :country => 'New Zealand' })

					if @configurator[:modules][:separate_delivery_address] && @configurator[:modules][:separate_delivery_address][:value]
						@delivery_address = Address.new({ :country => 'New Zealand' })
					end
				end

				if (@order.delivery_address && @order.delivery_address.country)
					@shipping_zones = ShippingZone.zones_for(@order.delivery_address.country)
					@shipping_zone = @order.shipping_zone
				elsif (@order.billing_address && @order.billing_address.country)
					@shipping_zones = ShippingZone.zones_for(@order.billing_address.country)
					@shipping_zone = @order.shipping_zone
				elsif (@shipping_zones)
					@shipping_zone = @shipping_zones.first
				else
					@shipping_zone = nil

					@shipping_zones = ShippingZone.find(:all)

#					if @shipping_zone.countries
#						@shipping_zones = ShippingZone.zones_for(@shipping_zone.countries.first)
#					end
				end

				@subtotal = @order.subtotal = @cart.subtotal * @multiplier
				@shipping_cost = @order.shipping_cost = @cart.shipping_cost(@shipping_zone)
				@total = @order.total = @subtotal + @shipping_cost
			end
		end
	end


	# AJAX method for rendering a checkout summary. Mostly this is needed because we
	# automatically update the shipping zones and costs when the user changes their country, so
	# we need to recalculate totals and so forth.
	#
	# <b>Template:</b> <tt>cart/_checkout_summary.rhtml</tt>
	def checkout_summary
		@cart = find_cart
		@items = @cart.items

		@multiplier = 1.0
		if @cart.priced and @cart.priced == 0
			@multiplier = 1.1
		end

		# should really put some conditions in here so only Option's that are used in the Items
		# in the cart are included.
		@options = Option.find(:all)

		# create the 'option_values' array, which is an array (indexed by Product id) of arrays
		# (indexed by Option id) of OptionValue's. Each LineItem will incur a single DB hit
		# (better than before) for its possible OptionValue's, as well as the DB hit to get all
		# the LineItem's, and all the Option's.
		@option_values = Array.new
		@items.each do |cur_item|
			@option_values[cur_item.product.id] = Array.new

			product_option_values = cur_item.product.product_option_values
			product_option_values.each do |cur_product_option_value|
				cur_option_value = OptionValue.find(cur_product_option_value[:option_value_id])
				if !@option_values[cur_item.product.id][cur_option_value[:option_id]]
					@option_values[cur_item.product.id][cur_option_value[:option_id]] = Array.new
				end
				@option_values[cur_item.product.id][cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
			end
		end

		if @current_user[:sees_wholesale]
			@first_wholesale_order = true

			old_wholesale_order = @current_user.orders.find(:first, :conditions => [ "wholesale=true AND status != 'in_progress' AND status != 'draft'" ])

			if old_wholesale_order && !old_wholesale_order.empty?
				@first_wholesale_order = false
			end
		end

		if !params[:shipping_zone_id] or params[:shipping_zone_id].to_i.zero?
			@shipping_zone = nil
		else
			@shipping_zone = ShippingZone.find(params[:shipping_zone_id])
		end
		@subtotal = @cart.subtotal
		@shipping_cost = @cart.shipping_cost(@shipping_zone)
		@total = @subtotal + @shipping_cost
		render :partial => 'checkout_summary'
	end


	# AJAX method for rendering a list of shipping zones available for the user's chosen country.
	# Mostly this is needed because we automatically update the shipping zones and costs when the
	# user changes their country, so we need to recalculate totals and so forth.
	#
	# <b>Template:</b> <tt>cart/_shipping_zone_selector.rhtml</tt>
	def shipping_zone_selector
		@shipping_zones = ShippingZone.zones_for(params[:country] || 'New Zealand')
		render :partial => 'shipping_zone_selector'
	end


	# Checks to see if there is an active payment gateway for the site. If there is, then
	# redirect to it (since it will usually be a PHP script rather than a Rails action); if not,
	# simply proceed to the part where we mark the order as complete.
	def payment_gateway
    redirect_to :action => :order_complete, :id => params[:id]
    #		@gateway = Plugin.payment_module
    #		if @gateway.script.nil?
    #			find_cart.empty!
    #			redirect_to :action => :order_complete, :id => params[:id]
    #		else
    #			redirect_to @gateway.script + '?id=' + params[:id]
    #		end
	end


	# Mark an Order as complete in the database. The security of this is a little dodgy, but I'm
	# relying on the fact that a shopkeeper isn't stupid enough to ship an order without making
	# sure it's been paid for (perhaps this isn't such a valid assumption).
	#
	# Afterwards, send notification emails to the user and the shopkeeper, and then empty the
	# cart and display a nice message.
	#
	# <b>Template:</b> <tt>cart/order_complete.rhtml</tt>
	def order_complete
		payment_module = Plugin.payment_module
		desired_status = payment_module.script.nil? ? 'in_progress' : 'awaiting_shipping'
		if params[:id] and @order = Order.find(params[:id])
			if @order and @order.status == desired_status
				@cart = find_cart
				unless @cart.is_empty?
					Postman.deliver_confirm(@configurator, @order)
					Postman.deliver_sent(@configurator, @order)
					@cart.empty!
				end
			end

			@show_barcodes_link = false
			if @current_user[:sees_wholesale]
				last_order = @current_user.orders.find(:first, :conditions => "id != #{@order[:id]} AND status != 'in_progress' AND status != 'draft'", :order => "created_at desc")

				the_file = "#{RAILS_ROOT}#{@configurator[:modules][:barcodes_spreadsheet_path][:value]}#{@configurator[:modules][:barcodes_spreadsheet_filename][:value]}"

				spreadsheet_exists = File.file? the_file

				unless last_order && spreadsheet_exists && (last_order[:created_at] > File.stat(the_file).mtime)
					@show_barcodes_link = true
				end
			end
		else
			redirect_to '/'
		end
	end


	# Show a login page. This particular login page also handles registering as a new user, which
	# is quite handy, and very straightforward for the users.
	#
	# <b>Template:</b> <tt>cart/login.rhtml</tt>
	def login
		if params[:register] && params[:user]
			@user = User.new(params[:user])
			@user.hash_algorithm = User.hash_algorithm_to_i(@configurator[:application][:password_hashing][:value])
			if @user.save
				session[:user_id] = @user.id
				redirect_to :action => :checkout
			end
		else
			@user = User.new
		end
	end
end
