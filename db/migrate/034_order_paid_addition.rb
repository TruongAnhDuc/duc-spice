# This migration changes the database schema by adding a 'paid' field to the orders table, which
# indicates the amount that the user has paid.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class OrderPaidAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

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
			items.inject(0.0) { |sum, i| sum + i.total_unit_price * i.quantity }
		end

		# Returns the total to pay for this order (subtotal + shipping costs)
		def total
			subtotal + (shipping_cost || 0.0)
		end
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new field
	def self.up
		add_column :orders, :paid, :float, :null => false, :default => 0.00
		execute 'ALTER TABLE `orders` CHANGE `paid` `paid` DECIMAL( 8, 3 ) NOT NULL DEFAULT \'0.00\';'

		# need to set 'paid' amounts correctly for old orders
		Order.find(:all, :conditions => [ "status = 'completed' OR status = 'awaiting_shipping'" ]).each do |cur_order|
			cur_order.paid = cur_order.total
			cur_order.save
		end

		puts 'Migration from schema 33 -> 34 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new field
	def self.down
		remove_column :orders, :paid

		puts 'Migration from schema 34 -> 33 complete'
	end
end
