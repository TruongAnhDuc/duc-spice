require File.dirname(__FILE__) + '/../test_helper'

class OrderTest < Test::Unit::TestCase
	fixtures :shipping_zones, :addresses, :line_items, :orders, :products, :users, :line_item_option_values, :product_option_values, :option_values, :options

	def test_assotiations
		assert_kind_of Address, orders(:large_meal).billing_address
		assert_equal orders(:large_meal).billing_address, addresses(:forkeds_house)
	end

	# test totaling seems to be working
	def test_order_methods
		the_order = orders(:armed_meal)

		cur_line_items = []
		the_order.items.each do |cur_item|
			if cur_item[:order_id] == the_order.id
				cur_line_items << cur_item
			end
		end

		items_total = 0.0
		cur_line_items.each do |cur_item|
			items_total += cur_item.total_unit_price
		end

		assert_equal the_order.subtotal.to_f.to_s, items_total.to_f.to_s
	end
end
