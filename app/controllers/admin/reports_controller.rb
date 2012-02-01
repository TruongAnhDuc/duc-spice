# Controller for all admin-level functions for reports. Checks to see if the currently logged-in
# user is a staff member before allowing access

class Admin::ReportsController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


#SNIP=orders_report
# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature
	# Creates a Report listing orders in the specified time period in Excel format for download.
	#
	# <b>Template:</b> <tt>admin/reports/orders.rhtml</tt> (option interface only)
	def orders
		@current_area = 'orders_report'
		@current_menu = 'reports'

		if request.post? || (request.get? && params[:page])
			@report_title = 'Orders'
			filename = 'reports/orders'
			@criteria = ["status='completed'"]

			@page = (params[:page] || 1).to_i
			@items_per_page = 20
			@offset = (@page - 1) * @items_per_page

			if params[:start_date]
				@start_date = ffs_parse_date(params[:start_date])

				@criteria << "(created_at >= '" + @start_date.strftime('%Y-%m-%d') + "')"
				filename += '-' + @start_date.strftime('%Y-%m-%d')
				@report_title += ': ' + @start_date.strftime('%d/%m/%Y')
			end

			if params[:end_date]
				# We want to show records that fall before the day after the end date
				@end_date = ffs_parse_date(params[:end_date])
				query_end_date = @end_date + 1

				@criteria << "(created_at <= '" + query_end_date.strftime('%Y-%m-%d') + "')"
				filename += '-to-' + @end_date.strftime('%Y-%m-%d')
				@report_title += ' to ' + @end_date.strftime('%d/%m/%Y')
			else
				@report_title += ' to present'
			end

			@order_count = Order.count(@criteria.join(' AND '))
			@pages = Paginator.new(self, @order_count, @items_per_page, @page)
			@orders = Order.find(
				:all,
				:conditions => @criteria.join(' AND '),
				:order => 'created_at DESC',
				:offset => params[:download] ? 0 : @offset,
				:limit => params[:download] ? nil : @items_per_page
			)

			# make Excel file if download is selected - otherwise render in page
			if params[:download]
				@rows = @orders.collect { |x| [ x.id, [x.created_at, :date], x.user.to_s, x.delivery_address ? x.delivery_address.country : x.billing_address.country, x.items.count, [x.total, :price] ] }

				@report_title += ' ' + Date.today.strftime('%d/%m/%Y')
				filename += '.xls'

				report = Report.new filename
				report.write 0, 0, @report_title, :title
				report.write 1, 0, [ 'ID', 'Date', 'User', 'Country', 'Items', 'Total' ], :heading
				report.write_rows @rows
				report.close

				@headers['Expires'] = '0'
				@headers['Cache-Control'] = 'must-revalidate,post-check=0,pre-check=0'
				@headers['Pragma'] = 'public'

				send_file filename, :type => 'application/vnd.ms-excel', :stream => false
				File.delete filename
			end
		else
			@start_date = @end_date = Date.today
		end
	end
# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
#/SNIP=orders_report


#SNIP=customers_report
# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature
	# Creates a Report listing all users of the site with their purchase totals.
	#
	# <b>Template:</b> <tt>admin/reports/customers.rhtml</tt> (option interface only)
	def customers
		@current_area = 'customers_report'
		@current_menu = 'reports'

		if request.post? || (request.get? && params[:page])
			@report_title = 'Customers'
			filename = 'reports/customers'
			# Filter out the demo admin.  This should only need to happen when demo mode is enabled.
			# We re-check the config here as the @demo_user is tested against the currently-logged-in user.
			demo_admin_local = !(!@configurator[:demo] or !@configurator[:demo][:enabled] or !@configurator[:demo][:enabled][:value])
			@criteria = demo_admin_local ? ['email <> \'' + @configurator[:demo][:user][:value] + '\''] : ['1']

			@page = (params[:page] || 1).to_i
			@items_per_page = 20
			@offset = (@page - 1) * @items_per_page

			@user_count = User.count(@criteria.join(' AND '))
			@pages = Paginator.new(self, @user_count, @items_per_page, @page)
			@users = User.find(
				:all,
				:conditions => @criteria.join(' AND '),
				:order => 'last_name ASC, first_name ASC',
				:offset => params[:download] ? 0 : @offset,
				:limit => params[:download] ? nil : @items_per_page
			)

			# make Excel file if download is selected - otherwise render in page
			if params[:download]
				@rows = @users.collect { |x| [ x.id, x.first_name, x.last_name, x.email, c = x.orders.count, x.orders.inject(0) { |sum, o| sum + o.items.inject(0) { |i_total, i| i_total + i.quantity } }, [ t = x.orders.inject(0.0) { |sum, o| sum + o.total }, :price ], [ (c > 0 ? t / c : 0.0), :price ] ] }

				@report_title += ' ' + Date.today.strftime('%d/%m/%Y')
				filename += '.xls'

				report = Report.new filename
				report.write 0, 0, @report_title, :title
				report.write 1, 0, [ 'ID', 'First Name', 'Last Name', 'Email', 'Orders', 'Items', 'Total', 'Average' ], :heading
				report.write_rows @rows
				report.close

				@headers['Expires'] = '0'
				@headers['Cache-Control'] = 'must-revalidate,post-check=0,pre-check=0'
				@headers['Pragma'] = 'public'

				send_file filename, :type => 'application/vnd.ms-excel', :stream => false
				File.delete filename
			end
		else

		end
	end
# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
#/SNIP=customers_report


#SNIP=products_report
# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature
	# Creates a Report product sales in the specified time period and (optionally) category in Excel format for download.
	#
	# <b>Template:</b> <tt>admin/reports/products.rhtml</tt> (option interface only)
	#
	# <b>Todo:</b> May not work so well with products in more than one category.
	def products
		@current_area = 'products_report'
		@current_menu = 'reports'

		if request.post? || (request.get? && params[:page])
			@report_title = 'Products Sold'
			filename = 'reports/products'

			@page = (params[:page] || 1).to_i
			@items_per_page = 20
			@offset = (@page - 1) * @items_per_page

			@criteria = ["orders.status='completed'"]
			@joins = [
				'JOIN products ON products.id=line_items.product_id',
				'JOIN orders ON line_items.order_id=orders.id',
				'JOIN categories_products ON categories_products.product_id=line_items.product_id'
			]

			if params[:start_date]
				@start_date = ffs_parse_date(params[:start_date])

				@criteria << "(orders.created_at >= '" + @start_date.strftime('%Y-%m-%d') + "')"
				filename += '-' + @start_date.strftime('%Y-%m-%d')
				@report_title += ': ' + @start_date.strftime('%d/%m/%Y')
			end

			if params[:end_date]
				# We want to show records that fall before the day after the end date
				@end_date = ffs_parse_date(params[:end_date])
				query_end_date = @end_date + 1

				@criteria << "(orders.created_at <= '" + query_end_date.strftime('%Y-%m-%d') + "')"
				filename += '-to-' + @end_date.strftime('%Y-%m-%d')
				@report_title += ' to ' + @end_date.strftime('%d/%m/%Y')
			else
				@report_title += ' to present'
			end

			if params[:categories] and !params[:categories].empty?
				@criteria << '(' + params[:categories].collect { |c| "(categories_products.category_id = #{c})" }.join(' OR ') + ')'
				@report_title += ' (' + params[:categories].collect { |c| Category.find(c.to_i).name }.join(', ') + ')'
			else
				@report_title += ' (ALL categories)'
			end

			# aagghhhh...
			@line_item_count = LineItem.count_by_sql('
				SELECT
				  COUNT(DISTINCT line_items.product_id)
				FROM line_items
			' + @joins.join(" ") + " WHERE " + @criteria.join(" AND ")
			)

			@pages = Paginator.new(self, @line_item_count, @items_per_page, @page)
			@line_items = LineItem.find(
				:all,
				:conditions => @criteria.join(" AND "),
				:order => "products.product_name ASC",
				:joins => @joins.join(" "),
#				:group => 'products.id',
#				:select => 'line_items.*, SUM(quantity) AS units_sold, SUM(unit_price * quantity) AS total_revenue',
				:offset => params[:download] ? 0 : @offset,
				:limit => params[:download] ? nil : @items_per_page
			)

			# fill in the data array, indexed by product_id
			@data = Hash.new
			@line_items.each do |cur_line_item|
				unless @data[cur_line_item[:product_id]] && @data[cur_line_item[:product_id]]["id"]
					@data[cur_line_item[:product_id]] = Hash.new

					@data[cur_line_item[:product_id]]["id"] = cur_line_item[:product_id]
					@data[cur_line_item[:product_id]]["code"] = cur_line_item.product.product_code
					@data[cur_line_item[:product_id]]["product"] = cur_line_item.product.name

					@data[cur_line_item[:product_id]]["units"] = 0
					@data[cur_line_item[:product_id]]["price"] = 0
					@data[cur_line_item[:product_id]]["total"] = 0
				end

				@data[cur_line_item[:product_id]]["units"] += cur_line_item[:quantity]
				@data[cur_line_item[:product_id]]["price"] = cur_line_item.total_unit_price
				@data[cur_line_item[:product_id]]["total"] += cur_line_item[:quantity] * cur_line_item.total_unit_price
			end

			# make Excel file if download is selected - otherwise render in page
			if params[:download]
				@rows = Array.new
				@data.each_pair do |x, cur_row|
					@rows << [ cur_row["id"], cur_row["code"], cur_row["product"], cur_row["units"], cur_row["price"], cur_row["total"] ]
				end

				@report_title += ' ' + Date.today.strftime('%d/%m/%Y')
				filename += '.xls'

				report = Report.new filename
				report.write 0, 0, @report_title, :title
				report.write 1, 0, [ 'ID', 'Code', 'Product', 'Units', 'Price', 'Total' ], :heading
				report.write_rows @rows
				report.close

				@headers['Expires'] = '0'
				@headers['Cache-Control'] = 'must-revalidate,post-check=0,pre-check=0'
				@headers['Pragma'] = 'public'

				send_file filename, :type => 'application/vnd.ms-excel', :stream => false
				File.delete filename
			end
		else
			@start_date = @end_date = Date.today
		end
	end
# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
#/SNIP=products_report


	# Creates a Report product sales in the specified time period and (optionally) category in
	# Excel format for download. Divides sales by whether the product was bought at full retail
	# pricing, or via wholesale
	#
	# <b>Template:</b> <tt>admin/reports/products_by_type.rhtml</tt>
	def products_by_type
		@current_area = "products_by_type_report"
		@current_menu = "reports"

		if request.post? || (request.get? && params[:page])
			@report_title = "Products Sold by Type"
			filename = "reports/products_by_type"

			@page = (params[:page] || 1).to_i
			@items_per_page = 20
			@offset = (@page - 1) * @items_per_page

			@criteria = ["orders.status='completed'"]
			@joins = [
				'JOIN products ON products.id=line_items.product_id',
				'JOIN orders ON line_items.order_id=orders.id',
				'JOIN categories_products ON categories_products.product_id=line_items.product_id'
			]

			if params[:start_date]
				@start_date = ffs_parse_date(params[:start_date])

				@criteria << "(orders.created_at >= '" + @start_date.strftime('%Y-%m-%d') + "')"
				filename += '-' + @start_date.strftime('%Y-%m-%d')
				@report_title += ': ' + @start_date.strftime('%d/%m/%Y')
			end

			if params[:end_date]
				# We want to show records that fall before the day after the end date
				@end_date = ffs_parse_date(params[:end_date])
				query_end_date = @end_date + 1

				@criteria << "(orders.created_at <= '" + query_end_date.strftime('%Y-%m-%d') + "')"
				filename += '-to-' + @end_date.strftime('%Y-%m-%d')
				@report_title += ' to ' + @end_date.strftime('%d/%m/%Y')
			else
				@report_title += ' to present'
			end

			if params[:categories] and !params[:categories].empty?
				@criteria << '(' + params[:categories].collect { |c| "(categories_products.category_id = #{c})" }.join(' OR ') + ')'
				@report_title += ' (' + params[:categories].collect { |c| Category.find(c.to_i).name }.join(', ') + ')'
			else
				@report_title += ' (ALL categories)'
			end

			# aagghhhh...
			@line_item_count = LineItem.count_by_sql('
				SELECT
				  COUNT(DISTINCT line_items.product_id)
				FROM line_items
			' + @joins.join(" ") + " WHERE " + @criteria.join(" AND ")
			)

			@pages = Paginator.new(self, @line_item_count, @items_per_page, @page)
			@line_items = LineItem.find(
				:all,
				:conditions => @criteria.join(" AND "),
				:order => "products.product_name ASC",
				:joins => @joins.join(" "),
#				:group => "products.id",
#				:select => "line_items.*, SUM(quantity) AS units_sold, SUM(unit_price * quantity) AS total_revenue",
				:offset => params[:download] ? 0 : @offset,
				:limit => params[:download] ? nil : @items_per_page
			)

			# fill in the data array, indexed by product_id
			@data = Hash.new
			@line_items.each do |cur_line_item|
				unless @data[cur_line_item[:product_id]] && @data[cur_line_item[:product_id]]["id"]
					@data[cur_line_item[:product_id]] = Hash.new

					@data[cur_line_item[:product_id]]["id"] = cur_line_item[:product_id]
					@data[cur_line_item[:product_id]]["code"] = cur_line_item.product.product_code
					@data[cur_line_item[:product_id]]["product"] = cur_line_item.product.name

					@data[cur_line_item[:product_id]]["units_r"] = 0
					@data[cur_line_item[:product_id]]["price_r"] = 0
					@data[cur_line_item[:product_id]]["total_r"] = 0
					@data[cur_line_item[:product_id]]["units_w"] = 0
					@data[cur_line_item[:product_id]]["price_w"] = 0
					@data[cur_line_item[:product_id]]["total_w"] = 0
					@data[cur_line_item[:product_id]]["total"] = 0
				end

				if cur_line_item.order.wholesale
					@data[cur_line_item[:product_id]]["units_w"] += cur_line_item[:quantity]
					@data[cur_line_item[:product_id]]["price_w"] = cur_line_item.total_unit_price
					@data[cur_line_item[:product_id]]["total_w"] += cur_line_item[:quantity] * cur_line_item.total_unit_price
				else
					@data[cur_line_item[:product_id]]["units_r"] += cur_line_item[:quantity]
					@data[cur_line_item[:product_id]]["price_r"] = cur_line_item.total_unit_price
					@data[cur_line_item[:product_id]]["total_r"] += cur_line_item[:quantity] * cur_line_item.total_unit_price
				end
				@data[cur_line_item[:product_id]]["total"] += cur_line_item[:quantity] * cur_line_item.total_unit_price
			end

			# make Excel file if download is selected - otherwise render in page
			if params[:download]
				@rows = Array.new
				@data.each_pair do |x, cur_row|
					@rows << [ cur_row["id"], cur_row["code"], cur_row["product"], cur_row["units_r"], cur_row["price_r"], cur_row["total_r"], cur_row["units_w"], cur_row["price_w"], cur_row["total_w"], cur_row["total"] ]
				end

				@report_title += ' ' + Date.today.strftime('%d/%m/%Y')
				filename += ".xls"

				report = Report.new filename
				report.write 0, 0, @report_title, :title
				report.write 1, 0, [ "ID", "Code", "Product", "Units (RTL)", "Price (RTL)", "Total (RTL)", "Units (WSL)", "Price (WSL)", "Total (WSL)", "Total" ], :heading
				report.write_rows @rows
				report.close

				@headers['Expires'] = '0'
				@headers['Cache-Control'] = 'must-revalidate,post-check=0,pre-check=0'
				@headers['Pragma'] = 'public'

				send_file filename, :type => 'application/vnd.ms-excel', :stream => false
				File.delete filename
			end
		else
			@start_date = @end_date = Date.today
		end
	end
end
