# This migration changes the database schema by adding 'extra_cost' and 'extra_weight' fields to
# the LineItemOptionValue class.

# Weight and Cost will now be stored in the LineItem table, caching the results of adding up any
# changes due to product option cost/weight modifications (which otherwise require chasing through
# join tables every time).

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class LineItemOptionValueCostWeightAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################


# Represents a user's product selection, either in their cart or as part of an Order. Contains
# information on price, quantity and options.

class LineItem < ActiveRecord::Base
	belongs_to :product
	belongs_to :order
	has_many :line_item_option_values, :dependent => :destroy
	has_many :option_values, :through => :line_item_option_values

	# Creates a LineItem for a given product.
	def self.for_product(product, quantity = 1)
		item = self.new
		item.quantity = quantity
		item.product = product
		item.unit_price = product.price
		item.unit_weight = product.weight
		# can't add the option_values here, because HaBtM relationships have to be created
		# AFTER both sides of the relationship are saved to the db.
		item
	end

	# Sets a product option.
	def set_option(value)
		if value.is_a? Array
			value.each do |cur_value|
				o_v = OptionValue.find(cur_value)
				self.line_item_option_values << LineItemOptionValue.new(:option_value => cur_value, :extra_cost => o_v.extra_cost, :extra_weight => o_v.extra_weight)
			end
		else
			o_v = OptionValue.find(value)
			self.line_item_option_values << LineItemOptionValue.new(:option_value => value, :extra_cost => o_v.extra_cost, :extra_weight => o_v.extra_weight)
		end
	end

	# Removes the selected product options
	def clear_options
		self.option_values.clear
	end

	# Returns +true+ if this LineItem is the same as another one.
	def same_as?(l2)
		self.product.id == l2.product.id && self.option_values == l2.option_values
	end

	# returns the total cost of this LineItem, taking into account extra-cost Options
	def total_unit_price
		total = self.unit_price

		liovs = self.line_item_option_values
		liovs.each do |cur_liov|
			total += cur_liov.extra_cost
		end

		total
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


	# Represents a relationship between a LineItem and an Option's concrete class (an OptionValue).
	class LineItemOptionValue < ActiveRecord::Base
		belongs_to :line_item
		belongs_to :option_value

		# to ensure we can only have 1 of each concrete option for each line_item
		validates_uniqueness_of :option_value_id, :scope => :line_item_id
	end

	# Represents a value for an Option.
	class OptionValue < ActiveRecord::Base
		belongs_to :option

	# cannot use HaBtM when the join table has attributes - need to use a join Model rather than
	# just a join Table
	#	has_and_belongs_to_many :products, :join_table => 'product_option_values', :order => "id"
		has_many :product_option_values, :dependent => :destroy
	# NEEDS RAILS v1.1
	#	has_many :products, :through => :product_option_values

		has_many :line_item_option_values, :dependent => :destroy
		has_many :line_items , :through => :line_item_option_values

		acts_as_list :order => 'position', :scope => 'option_id'
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new columns
	def self.up
		@actions = ''

		add_column :line_item_option_values, :extra_cost, :float, :null => false, :default => 0.0
#	this is what we need - but you need Rails 1.1+ (*sigh*)
#		add_column :line_item_option_values, :extra_cost, :decimal, :precision => 10, :scale => 2, :null => false, :default => 0.00
#	Rails 1.0 hack - need to edit the db retroactively to be decimal with:
		execute 'ALTER TABLE `line_item_option_values` CHANGE `extra_cost` `extra_cost` DECIMAL( 10, 2 ) NOT NULL DEFAULT \'0.00\';'

		add_column :line_item_option_values, :extra_weight, :float, :null => false, :default => 0.0
		execute 'ALTER TABLE `line_item_option_values` CHANGE `extra_weight` `extra_weight` DECIMAL( 8, 3 ) NOT NULL DEFAULT \'0.00\';'
		@actions += 'extra cost and weight columns added' + "\n"

		# now retro-spectively add data for the new columns into any existing
		# line_item_option_values
		OptionValue.find(:all).each do |cur_o_v|
			cur_o_v.line_item_option_values.each do |cur_liov|
				# note this is just an approximation - previously product options couldn't
				# alter weight, so this was not factored in
#				cur_liov.extra_cost = cur_o_v.extra_cost
#				cur_liov.extra_weight = cur_o_v.extra_weight
#				cur_liov.save
# It looks like Rails can't do this without an ID column, so for the time being we'll just brute-force it.
# The Composite Keys gem doesn't support HaBtM relationships yet so there's no point installing it...
				execute 'UPDATE `line_item_option_values` SET extra_cost = ' + cur_o_v.extra_cost.to_s + ', extra_weight = ' + cur_o_v.extra_weight.to_s + ' WHERE line_item_id = ' + cur_liov.line_item_id.to_s + ' AND option_value_id = ' + cur_liov.option_value_id.to_s + ';'
			end
		end

#		LineItemOptionValue.find(:all, :include => [:option_value]).each do |cur_item|
#			cur_item.extra_cost = cur_item.option_value.extra_cost
#			cur_item.extra_weight = cur_item.option_value.extra_weight
#			cur_item.save
#		end
		@actions += 'extra cost and weight columns filled' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 6 -> 7 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns
	def self.down
		@actions = ''

		remove_column :line_item_option_values, :extra_cost
		remove_column :line_item_option_values, :extra_weight
		@actions += 'extra cost and weight columns dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 7 -> 6 complete'
	end
end
