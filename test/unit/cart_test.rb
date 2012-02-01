require File.dirname(__FILE__) + '/../test_helper'

# Ahh, testing carts. Throwing a mate in the cart, and running really fast across the supermarket
# carpark...
class CartTest < Test::Unit::TestCase
	fixtures :products, :option_values, :product_option_values

	def setup
		@cart = Cart.new
	end

	# tests the empty? and empty! methods
	def test_emptiness
		assert_equal @cart.is_empty?, true

		@cart.add_product products(:cow)

		assert_equal @cart.is_empty?, false

		@cart.empty!

		assert_equal @cart.is_empty?, true
	end

	# adding a unique product should create a second line item
	def test_add_unique_products
		@cart.add_product products(:chicken)
		@cart.add_product products(:cow)

		assert_equal products(:chicken).price + products(:cow).price, @cart.total_price
		assert_equal 2, @cart.items.size
		assert_equal 2, @cart.total_items

		assert_equal products(:chicken).weight + products(:cow).weight, @cart.total_weight
	end

	# adding a duplicate product should just increment the quantity of that line item
	def test_add_duplicate_product
		@cart.add_product products(:chicken)
		@cart.add_product products(:chicken)

		assert_equal 2 * products(:chicken).price, @cart.total_price
		assert_equal 1, @cart.items.size
		assert_equal 2, @cart.total_items

		assert_equal 2 * products(:chicken).weight, @cart.total_weight
	end

	# adding products with ProductOptions
	def test_add_optionized_product
		option_values_array = [option_values(:gun1)]
		@cart.add_product(products(:cow2), 1, option_values_array)

#		assert_equal '1000.0', option_values(:gun1).extra_cost.to_f.to_s
#		assert_equal '115000.0', products(:cow2).price.to_f.to_s
		assert_equal (products(:cow2).price + option_values(:gun1).extra_cost).to_f.to_s, @cart.total_price.to_f.to_s
#		assert_equal '116000.0', @cart.total_price.to_f.to_s

		@cart.empty!

		option_values_array = [option_values(:gun1)]
		@cart.add_product(products(:cow3), 1, option_values_array)

#		assert_equal '1000.0', option_values(:gun1).extra_cost.to_f.to_s
		option_value_cost = products(:cow3).discount_is_abs ? option_values(:gun1).extra_cost : Product.discount_price(option_values(:gun1).extra_cost, products(:cow3).discount, products(:cow3).discount_is_abs)
#		assert_equal '700.0', option_value_cost.to_f.to_s
#		assert_equal '84000.0', products(:cow3).price.to_f.to_s
		assert_equal (products(:cow3).price + option_value_cost).to_f.to_s, @cart.total_price.to_f.to_s
#		assert_equal '84700.0', @cart.total_price.to_f.to_s

		@cart.empty!

		option_values_array = [option_values(:diff1)]
		@cart.add_product(products(:optioner), 1, option_values_array)

#		assert_equal '180.0', @cart.total_price.to_f.to_s
		option_value_cost = products(:optioner).discount_is_abs ? option_values(:diff1).extra_cost : Product.discount_price(option_values(:diff1).extra_cost, products(:optioner).discount, products(:optioner).discount_is_abs)
		assert_equal (products(:optioner).price + option_value_cost).to_f.to_s, @cart.total_price.to_f.to_s
	end

	# adding a unique product should create a second line item
	def test_add_wholesale_products
		@cart.add_product products(:cow2), 1, [], true
		@cart.add_product products(:cow3), 1, [], true

		assert_equal (products(:cow2).price(true) + products(:cow3).price(true)).to_s, @cart.total_price.to_s
		assert_not_equal products(:cow2).base_price + products(:cow3).base_price, @cart.total_price
		assert_equal 2, @cart.items.size
		assert_equal 2, @cart.total_items
	end
end
