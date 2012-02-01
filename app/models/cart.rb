# Class storing a user's current shopping cart.
# This class isn't persisted to the database, but survives as long as a user's session (so be
# careful not to put any sensitive data in here). The cart holds a collection of LineItem objects,
# which get persisted to the database when the user turns their cart selection into an Order (q.v.).

class Cart
	attr_reader :items
	attr_accessor :priced

	def initialize
		@items = []
	end

	# Checks if the cart is empty.
	def is_empty?
		@items.empty?
	end

	# Clears all items from the cart.
	def empty!
		@items = []
	end

	# Adds the specified product to the cart. Acts differently for FeaturedProducts, since what
	# we really want to do is put the base product into the cart (although possibly with a
	# different price).
	# Takes the following parameters:
	# * +product+ - the product to be added
	# * +quantity+ - how many to add
	# * +option_values+ - array of option_values for the product (if applicable).
	def add_product(product, quantity = 1, option_values = [], wholesale = false)
		line_item = LineItem.for_product(product, quantity, wholesale)

		option_values.each do |cur_option_value|
			o_v = OptionValue.find(cur_option_value)

			# make sure that discounts are applied to options as well as the base price
#			if product[:discount] && !product[:discount_is_abs] && product[:discount] > 0
#				line_item.set_option(o_v, product[:discount])
#			else
				line_item.set_option(o_v, wholesale)
#			end
		end

		item = @items.find { |i| i.same_as? line_item }
		if item
			item.quantity += quantity.to_i
		else
			@items << line_item
		end
	end

	# Deletes the specified item or items from the cart.
	def delete_product(item)
		if item.is_a? Enumerable
			item.each { |i| @items.delete i }
		else
			@items.delete(item)
		end
	end

	# Returns the total price of all the items in the cart.
	#
	# The same as subtotal? Should probably include shipping_cost just to be useful
	def total_price
		@items.inject(0.0) { |sum, i| sum + i.total_unit_price * i.quantity }
	end

	# Returns the total weight of all the items in the cart.
	def total_weight
		@items.inject(0.0) { |sum, i| sum + i.total_unit_weight * i.quantity }
	end

	# Returns the total number of items in the cart, accounting for products with quantities
	# greater than one.
	def total_items
		@items.inject(0) { |sum, i| sum + i.quantity }
	end

	# Returns the total price of all the items in the cart.
	def subtotal
		@items.inject(0.0) { |sum, i| sum + i.total_unit_price * i.quantity }
	end

	# Calculates the shipping cost for the items in the cart, based on the supplied ShippingZone
	# (or the default zone if none is given).
	def shipping_cost(shipping_zone = nil)
		shipping_zone ||= ShippingZone.default_zone

		item_cost = total_items * shipping_zone.per_item
		weight_cost = total_weight * shipping_zone.per_kg

		unless shipping_zone.formula.nil? || shipping_zone.formula.empty?
			formula = shipping_zone.formula.gsub('I', total_items.to_s).gsub('W', total_weight.to_s).gsub('V', subtotal.to_s).gsub('$', '')

			formula_cost = eval(formula)
		else
			formula_cost = 0
		end

		item_cost + weight_cost + formula_cost + shipping_zone.flat_rate
	end
end