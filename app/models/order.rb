# Represents a user's order.
# Holds a collection of LineItem objects representing the quantity and nature of the products
# chosen, as well as shipping and status information.

class Order < ActiveRecord::Base
	belongs_to :user
	has_many :items, :class_name => 'LineItem'
	belongs_to :shipping_zone
	belongs_to :billing_address, :class_name => 'Address', :foreign_key => :billing_address_id
	belongs_to :delivery_address, :class_name => 'Address', :foreign_key => :delivery_address_id

	validates_length_of :shipping_email, :minimum => 1, :message => 'Please enter your email address.'

	# Returns the total weight of all the items in the cart.
	def total_weight
		items.inject(0.0) { |sum, i| sum + i.total_unit_weight * i.quantity }
	end

	# Returns the total number of items in the cart, accounting for products with quantities
	# greater than one.
	def total_items
		items.inject(0) { |sum, i| sum + i.quantity }
	end

	# Returns the total price of all the items in the cart.
	def subtotal
		multiplier = 1.0
		unless priced
			multiplier = 1.1
		end

		items.inject(0.0) { |sum, i| sum + i.total_unit_price * i.quantity * multiplier }
	end

	# Returns the total to pay for this order (subtotal + shipping costs)
	def total
		subtotal + (shipping_cost || 0.0)
	end
end
