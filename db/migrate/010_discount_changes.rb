# This migration changes the database schema by adding a 'discount' field to the LineItem class. It
# also adds a boolean discount_is_abs fields to both the Product class and the LineItem class.

# Discounts will now be stored in the LineItem table, as the discount can vary over time, and needs
# to be frozen in LineItems. It also can vary between a Product and a FeaturedProduct of that same
# Product. Discounts can be stored in either a percentage or an absolute amount (assumed at this
# stage to always be $NZD), as signaled by the discount_is_abs field.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class DiscountChanges < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

# Represents a user's product selection, either in their cart or as part of an Order. Contains
# information on price, quantity and options.

class LineItem < ActiveRecord::Base
	belongs_to :product
	belongs_to :order
	has_many :line_item_option_values
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
#		option_values.each do |option|
#			options[option.id] ||= option.default_value
#		end
#		item.option_values = options
		item
	end

	# Sets a product option.
	def set_option(value, discount = nil)
		mult = 1
		if discount
			mult -= discount/100
		end

		if value.is_a? Array
#			value = value.join ','
			value.each do |cur_value|
				o_v = OptionValue.find(cur_value)
				self.line_item_option_values << LineItemOptionValue.new(:option_value => cur_value, :extra_cost => (mult * o_v.extra_cost), :extra_weight => o_v.extra_weight)
			end
		else
			o_v = OptionValue.find(value)
			self.line_item_option_values << LineItemOptionValue.new(:option_value => value, :extra_cost => (mult * o_v.extra_cost), :extra_weight => o_v.extra_weight)
		end
#		self.option_values << value
	end

	# Removes the selected product options
	def clear_options
		# this line _may_ be doing nothing
		self.option_values.clear
		# has_many :through needs this?
		self.line_item_option_values.clear
	end

	# Returns +true+ if this LineItem is the same as another one.
	def same_as?(l2)
		# comparing self.option_values with l2.option_values _should_ work, but doesn't. If you
		# instead compare the .line_item_option_values, it works...
		#
		# Does this mean has_many :through is a horrible hack? Maybe...
		self.product.id == l2.product.id && self.line_item_option_values == l2.line_item_option_values
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


# Represents a product in the database.
#
# Products have access to all the information about *one* item in the store. They can be configured
# using OptionValue and ProductOptionValue instances to display interfaces for users to choose
# colours and sizes.
#
# Atomic products have a +base_price+ variable that is read by the +price+ method. This allows
# Product subclasses like FeaturedProduct and CompositeProduct to override this behaviour: for
# example, a CompositeProduct's +price+ method will instead return the sum of the prices of the
# products of which it is comprised. The same goes for the +name+ method: the default behaviour is
# to display the value of the +product_name+ instance variable, but this is overridden in
# CompositeProduct to return the list of names of all its components instead.
#
# Currently there is a limit of one image per product. It is envisaged that eventually this will be
# expanded to support multiple images per item.

class Product < ActiveRecord::Base
	has_and_belongs_to_many :categories, :join_table => 'categories_products'

	validates_presence_of :product_code, :product_name

# cannot use HaBtM when the join table has attributes - need to use a join Model rather than just a
# join Table
#	has_and_belongs_to_many :option_values, :join_table => 'product_option_values'
	has_many :product_option_values, :dependent => :destroy
	has_many :option_values, :through => :product_option_values

	has_one :image, :conditions => 'type IS NULL'

	# URL for the product detail page for this product.
	def path
		if categories && categories.first
			'/products/' + categories.first.path + '/' + self.id.to_s + '.html'
		else
			'/products/' + self.id.to_s + '.html'
		end
	end

	# Price of this product.
	def price
		Product.discount_price(base_price, discount)
	end

	# Sets the price of this product by changing the underlying +base_price+ variable.
	def price=(value)
		base_price = value
	end

	# Return the weight of this product, for use in shipping calculations - note that this does
	# not take account of product options chosen.
	def weight
		base_weight
	end

	# Set the base weight of this product.
	def weight=(value)
		base_weight = value
	end

	# Return the name of this product.
	def name
		product_name
	end

	# Set the name of this product.
	def name=(value)
		product_name = value
	end

	# Return a thumbnail of this product, if it has an associated image.
	def thumbnail(width, height, scaling_mode = :fit)
		if image
			alt_text = image_alt_tag || image.caption
			"<img class=\"thumbnail\" src=\"/product_images/thumbnail/#{image.id}?width=#{width}&height=#{height}&mode=#{scaling_mode.to_s}\" width=\"#{width}\" height=\"#{height}\" alt=\"#{alt_text}\" title=\"#{self.name}\" />"
		else
			w = width - 2;
			h = height - 2;
			"<table class=\"no-image\"><tr><td style=\"width: #{w}px; height: #{h}px;\">(No image available)</td></tr></table>"
		end
	end

	# Highlights the description of this product based on a given set of search keywords.
	# Uses a clever ellipsification algorithm to extract relevant parts of the description (a
	# few words either side of the matched keyword).
	def highlight_description(keywords)
		re = Regexp.new('(' + keywords.join('|') + ')', Regexp::IGNORECASE)
		words = description.split
		fragments = {}
		indices = []
		words.each_with_index do |word, i|
			if word.match re
				indices << i
			end
		end

		windows = []
		current_window = []
		indices.each do |i|
			if !current_window.empty? and current_window.last < i - 5
				windows << current_window
				current_window = [i]
			else
				current_window << i
			end
		end
		windows << current_window

		fragments = windows.first(5).collect do |window|
			l = (window.first - 2 < 0) ? 0 : window.first - 2
			r = (window.last + 2 >= words.length) ? words.length - 1 : window.last + 2
			(l..r).collect { |i| words[i].gsub(re, '<strong>\1</strong>') }.join(" ")
		end

		fragments.join(' ... ').split.first(50).join(' ')
	end

	class << self
		# Utility method for performing a percentage discount on a given price.
		def discount_price(base_price, discount)
			base_price - ((discount * base_price).round / 100.00)
		end
	end
end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new columns
	def self.up
		@actions = ''

		add_column :products, :discount_is_abs, :boolean, :default => 0
		add_column :line_items, :discount, :float, :null => false, :default => 0.0
		add_column :line_items, :discount_is_abs, :boolean, :default => 0

		@actions += 'discount and discount_is_abs columns added' + "\n"

		# now retro-spectively add data for the new columns into any existing
		# line_items
		LineItem.find(:all).each do |cur_item|
			cur_item.discount = cur_item.product.discount
			cur_item.save
		end
		@actions += 'line_item discount column filled' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 9 -> 10 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns
	def self.down
		@actions = ''

		remove_column :products, :discount_is_abs
		remove_column :line_items, :discount
		remove_column :line_items, :discount_is_abs
		@actions += 'discount and discount_is_abs columns dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 10 -> 9 complete'
	end
end
