# This script will remove all In-Progress Orders that are older than the specified number of days
#
# Call this file with:
#
# script/console < cron/clean_in_progress.rb

max_age = 14 # in days

old_orders = Order.find(:all, :conditions => 'status = \'in_progress\' AND created_at < (CURDATE() - INTERVAL ' + max_age.to_s + ' DAY)')

if old_orders
	old_orders.each do |cur_order|
		cur_order.destroy
	end
end
