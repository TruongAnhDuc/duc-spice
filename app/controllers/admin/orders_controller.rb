# Controller for all admin-level functions for orders. Checks to see if the currently logged-in
# user is a staff member before allowing access

class Admin::OrdersController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout "admin"


	# Displays a list of orders and their status.
	#
	# <b>Template:</b> <tt>admin/orders/list.rhtml</tt>
	def list
		@current_area = 'orders'
		@current_menu = 'orders'

		sort_order ||= get_sort_order("s-date", "created_at")
		sort_order ||= get_sort_order("s-user", ["users.first_name", "users.last_name"])
		sort_order ||= get_sort_order("s-total", "total")
		sort_order ||= "created_at DESC"

		if params[:save] and params[:status] and params[:select]
			c = params[:select].keys.collect { |k| "id=#{k}" }.join(" OR ")
			Order.update_all "status='#{params[:status]}'", c
		end

		@page = (params[:page] || 1).to_i
		@items_per_page = 20
		@offset = (@page - 1) * @items_per_page

		where_parts = Array.new
		if params[:query] and !params[:query].empty?
			ids = params[:query].split
			# allows multiple id's to be entered (space separated)
			where_parts << "id in (" + ids.collect { |k| k.to_i }.join(",") + ")"
		end
		if params[:history_date] and !params[:history_date].empty?
			@history_date = ffs_parse_date(params[:history_date])
			# NOTE: This will only work with MySQL - comparing a Datetime and a Date should
			# (according to the SQL spec) generate an error.
			where_parts << "created_at like '" + @history_date.strftime('%Y-%m-%d') + "%'"
		end
		# in progress orders just clutter up the list, and confuse users (they're often bogus
		# or at the least transient or out-of-date)
		if params[:show_in_progress]
			@show_in_progress = "1"
		else
			where_parts << "status != 'in_progress'"
		end

		where_clause = where_parts.join(" AND ")

		if !where_clause || where_clause.empty?
			where_clause = "1"
		end

		@order_count = Order.count(where_clause)
		@pages = Paginator.new(self, @order_count, @items_per_page, @page)
		@orders = Order.find(
			:all,
			:conditions => where_clause,
			:order => sort_order,
			:offset => @offset,
			:limit => @items_per_page
		)
	end


	# Displays a list of orders that are currently awaiting shipping, and allows the user to select one or more orders
	# they have shipped. In this case, the order status is updated to '<tt>complete</tt>', and the customer receives
	# a shipping notification email to say their order is on its way.
	#
	# <b>Template:</b> <tt>admin/orders/pending.rhtml</tt>
	def pending
		@current_area = "pending_orders"
		@current_menu = "orders"

		sort_order ||= get_sort_order("s-date", "created_at")
		sort_order ||= get_sort_order("s-user", ["users.first_name", "users.last_name"])
		sort_order ||= get_sort_order("s-total", "total")
		sort_order ||= "created_at DESC"

		if params[:select]
			if params[:ship]
				params[:select].keys.each do |id|
					order = Order.find(id)
					Postman.deliver_shipped(@configurator, order)
					order.update_attribute("status", "completed")
				end
			elsif params[:fail]
				c = params[:select].keys.collect { |k| "id=#{k}" }.join(" OR ")
				Order.update_all "status='failed'", c
			end
		end

		@page = (params[:page] || 1).to_i
		@items_per_page = 20
		@offset = (@page - 1) * @items_per_page

		where_parts = Array.new
		if params[:query] and !params[:query].empty?
			ids = params[:query].split
			# allows multiple id's to be entered (space separated)
			where_parts << "id in (" + ids.collect { |k| k.to_i }.join(",") + ")"
		end
		if params[:history_date] and !params[:history_date].empty?
			@history_date = ffs_parse_date(params[:history_date])
			# NOTE: This will only work with MySQL - comparing a Datetime and a Date should
			# (according to the SQL spec) generate an error.
			where_parts << "created_at like '" + @history_date.strftime('%Y-%m-%d') + "%'"
		end
		where_parts << "status='awaiting_shipping'"
		where_clause = where_parts.join(" AND ")

		@order_count = Order.count(where_clause)
		@pages = Paginator.new(self, @order_count, @items_per_page, @page)
		@pending_orders = Order.find(
			:all,
			:conditions => where_clause,
			:order => sort_order,
			:offset => @offset,
			:limit => @items_per_page
		)
	end


	# Displays details of an individual order.
	#
	# <b>Template:</b> <tt>admin/orders/view.rhtml</tt>
	#
	# <b>Todo:</b> Display shipping details on this page!
	def view
		@current_menu = "orders"

		if params[:id]
			@order = Order.find(params[:id])

			if params[:update_freight]
				@order.shipping_cost = params[:order][:shipping_cost]
				if @order.save
					flash[:notice] = "Freight cost updated."
				else
					flash[:error] = "Unable to save new freight cost."
				end
			end

			@multiplier = 1.0
			unless @order.priced
				@multiplier = 1.1
			end

			@items = @order.items

			if @order.status == "awaiting_shipping"
				@current_area = "pending_orders"
			else
				@current_area = "orders"
			end

			# should really put some conditions in here so only Option's that are used in the
			# Items in the cart are included.
			@my_options = Option.find(:all)
			# The options array needs to be indexed by ID...
			@options = Array.new
			@my_options.each do |option|
				@options[option.id] = option
			end

			if @order.wholesale
				@first_wholesale_order = true

				old_wholesale_order = Order.find(:first, :conditions => [ "wholesale=true AND status != 'in_progress' AND status != 'draft' AND user_id = #{@order[:user_id]}" ], :order => [ "created_at ASC" ])

				if old_wholesale_order && old_wholesale_order[:id] != @order[:id]
					@first_wholesale_order = false
				end
			end

			# create the 'option_values' array, which is an array (indexed by Product id) of
			# arrays (indexed by Option id) of OptionValue's. Each LineItem will incur a
			# single DB hit (better than before) for its possible OptionValue's, as well as
			# the DB hit to get all the LineItem's, and all the Option's.
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

		else
			redirect_to :action => :list
		end
	end
end
