# Represents a user's product selection, either in their cart or as part of an Order. Contains
# information on price, quantity and options.

class LineItem < ActiveRecord::Base
	belongs_to :product
	belongs_to :order
	has_many :line_item_option_values
	has_many :option_values, :through => :line_item_option_values

	# Creates a LineItem for a given product.
	def self.for_product(product, quantity = 1, wholesale = false)
		item = self.new
		item.quantity = quantity
		item.product = product
		if wholesale
			item.unit_price = product.wholesale_base_price
		else
			item.unit_price = product.base_price
		end
		item.discount = product.discount
		item.discount_is_abs = product.discount_is_abs
		item.unit_weight = product.weight
		item.wholesale = wholesale
		# can't add the option_values here, because HaBtM relationships have to be created
		# AFTER both sides of the relationship are saved to the db.
#		option_values.each do |option|
#			options[option.id] ||= option.default_value
#		end
#		item.option_values = options
		item
	end

	# Sets a product option.
	def set_option(value, wholesale = false)
		mult = 1
		if discount
			unless discount_is_abs
				mult -= discount/100
			end
		end

		if value.is_a? Array
#			value = value.join ','
			value.each do |cur_value|
				o_v = OptionValue.find(cur_value)
				if wholesale
					the_extra_cost = o_v.wholesale_extra_cost
				else
					the_extra_cost = o_v.extra_cost
				end

				self.line_item_option_values << LineItemOptionValue.new(:option_value => cur_value, :extra_cost => (mult * the_extra_cost), :extra_weight => o_v.extra_weight)
			end
		else
			o_v = OptionValue.find(value)

			if wholesale
				the_extra_cost = o_v.wholesale_extra_cost
			else
				the_extra_cost = o_v.extra_cost
			end

			self.line_item_option_values << LineItemOptionValue.new(:option_value => value, :extra_cost => (mult * the_extra_cost), :extra_weight => o_v.extra_weight)
		end
#		self.option_values << value
	end

	# OMG, Rails doesn't define collection assignment for has_many if :through is used...
	def option_values=(new_option_values)
		new_option_values.delete('')
		new_option_values.each_index do |i|
			new_option_values[i] = OptionValue.find(new_option_values[i]) unless new_option_values[i].is_a?(OptionValue)
		end

		unless self.new_record?
			OptionValue.find(:all).each do |option_value|
				unless new_option_values.include?(option_value)
					if option_values.include?(option_value)
						LineItemOptionValue.find_by_option_value_id_and_line_item_id(option_value.id, id).destroy
					end
				end
			end

# this is the way it is due to the lack of '<<' for has_many :through in Rails 1.2- >:|
			for option_value in new_option_values
				self.line_item_option_values.create!(:option_value => option_value)
#				option_values << option_value unless option_values.include?(option_value)
			end
# don't reload the joins - this will hit the DB (and none will be found previously to the order being saved...)
#			line_item_option_values.reset
		end
	end

	# Removes the selected product options
	def clear_options
		# this line _may_ be doing nothing
		#self.option_values.clear
		# has_many :through needs this?
		self.line_item_option_values.clear

#		self.line_item_option_values.each do |liov|
#			liov.destroy
#		end
	end

	# Returns +true+ if this LineItem is the same as another one.
	#
	# WARNING - this doesn't check if the LineItems have the same prices etc - so if two
	# LineItems were created either side of a price-change, this would return TRUE!
	def same_as?(l2)
		# comparing self.option_values with l2.option_values _should_ work, but doesn't. If you
		# instead compare the .line_item_option_values, it works...
		#
		# Does this mean has_many :through is a horrible hack? Maybe...
		self.product.id == l2.product.id && self.line_item_option_values == l2.line_item_option_values
	end

	# returns the unit_price of this LineItem, appropriately discounted
	def final_unit_price
#		multiplier = order.priced ? 1.0 : 1.1

		Product.discount_price(self.unit_price, discount, discount_is_abs)
#* multiplier
	end

	# returns the total cost of this LineItem, taking into account extra-cost Options
	def total_unit_price
		total = self.unit_price

		total = Product.discount_price(total, discount, discount_is_abs)

		liovs = self.line_item_option_values
		liovs.each do |cur_liov|
			total += cur_liov.extra_cost
		end

		total
#		multiplier = order.priced ? 1.0 : 1.1

#		total * multiplier
	end

	# returns the total weight of this LineItem, taking into account extra-weight Options
	def total_unit_weight
		total = self.unit_weight

		liovs = self.line_item_option_values
		liovs.each do |cur_liov|
			total += cur_liov.extra_weight
		end

		total
	end
end
