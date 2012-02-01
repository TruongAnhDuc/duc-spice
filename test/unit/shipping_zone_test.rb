require File.dirname(__FILE__) + '/../test_helper'

# Tests for shipping zones - has a lot of crossover with Cart testing...
class ShippingZoneTest < Test::Unit::TestCase
	fixtures :shipping_zones
	fixtures :products

	def setup
		@cart = Cart.new
	end

	def test_free_shipping
		for counter in (1..7) do
			@cart.add_product products(:cow)
		end

		for counter in (1..5) do
			@cart.add_product products(:chicken)
		end

		assert_equal 12, @cart.total_items

		assert_equal 0.0, @cart.shipping_cost(shipping_zones(:default_free_shipping))
	end

	# tests the formulaic shipping method 'boxed_shipping'
	def test_boxed_shipping
		# first check that a single box is being sent for 7 items
		for counter in (1..2) do
			@cart.add_product products(:cow)
		end

		for counter in (1..5) do
			@cart.add_product products(:chicken)
		end

		assert_equal 7, @cart.total_items

		assert_equal 25.0, @cart.shipping_cost(shipping_zones(:boxed_shipping))

		# now check that 2 boxes are sent for 12 items
		for counter in (1..5) do
			@cart.add_product products(:cow)
		end

		assert_equal 12, @cart.total_items

		assert_equal 45.0, @cart.shipping_cost(shipping_zones(:boxed_shipping))
	end

	# tests the cost-per-item style shipping
	def test_itemized_shipping
		for counter in (1..2) do
			@cart.add_product products(:cow)
		end

		for counter in (1..5) do
			@cart.add_product products(:chicken)
		end

		assert_equal 7, @cart.total_items

		assert_equal 14.0, @cart.shipping_cost(shipping_zones(:itemized_shipping))

		for counter in (1..5) do
			@cart.add_product products(:cow)
		end

		assert_equal 12, @cart.total_items

		assert_equal 24.0.to_s, @cart.shipping_cost(shipping_zones(:itemized_shipping)).to_s
	end

	# tests the cost-per-weight style shipping
	def test_weighted_shipping
		for counter in (1..2) do
			@cart.add_product products(:cow)
		end

		for counter in (1..5) do
			@cart.add_product products(:chicken)
		end

		assert_equal 7, @cart.total_items

		assert_equal @cart.total_weight * 2, @cart.shipping_cost(shipping_zones(:weighted_shipping))

		for counter in (1..5) do
			@cart.add_product products(:cow)
		end

		assert_equal 12, @cart.total_items

		assert_equal @cart.total_weight * 2, @cart.shipping_cost(shipping_zones(:weighted_shipping))
	end
end
