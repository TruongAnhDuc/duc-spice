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
	validates_numericality_of :base_price, :discount, :base_weight

# cannot use HaBtM when the join table has attributes - need to use a join Model rather than just a
# join Table
#	has_and_belongs_to_many :option_values, :join_table => 'product_option_values'
	has_many :product_option_values, :dependent => :destroy
	has_many :option_values, :through => :product_option_values

	has_many :attribute_values, :order => :position
	has_many :reviews, :order => "reviews.created_at DESC"

	has_one :image, :conditions => 'type IS NULL'

	belongs_to :product_type

	has_many :quirk_values

	# URL for the product detail page for this product.
	def path
		if categories && categories.first
			'/' + categories.first.path + '/' + self.id.to_s + '-' + self.url_name + '.html'
		else
			root_cat = Category.find(1)

			'/' + root_cat.filename + '/' + self.id.to_s + '-' + self.url_name + '.html'
		end
	end

	# URL for the product reviews page for this product.
	def reviews_path
		if categories && categories.first
			'/' + categories.first.path + '/' + self.id.to_s + '-' + self.url_name + '-reviews.html'
		else
			root_cat = Category.find(1)

			'/' + root_cat.filename + '/' + self.id.to_s + '-' + self.url_name + '-reviews.html'
		end
	end

	# This is largely duplicated in featured_product.rb.
	def validate
		if(discount_is_abs)
			if(discount < 0.0)
				errors.add(:discount, "must be a positive number.")
			end
			if(discount > base_price)
				errors.add(:discount, "cannot be greater than the base price.")
			end
		else
			if(discount < 0.0 or discount > 100.0)
				errors.add(:discount, "must be between 0 and 100.")
			end
		end
		if(base_price.to_f < 0.0)
			errors.add(:base_price, "must be a positive number.")
		end
	end

	# Price of this product.
	def price(wholesale = false)
		if wholesale
			Product.discount_price(wholesale_base_price, discount, discount_is_abs)
		else
			Product.discount_price(base_price, discount, discount_is_abs)
		end
	end

	# See comments in featured_product.rb
	def raw_base_price
		base_price
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

	# See comments in featured_product.rb
	def raw_base_weight
		base_weight
	end

	# Set the base weight of this product.
	def weight=(value)
		base_weight = value
	end

	# String version of the product should be its name
	def to_s
		product_name
	end

	# Return the name of this product.
	def name
		product_name
	end

	# Set the name of this product.
	def name=(value)
		product_name = value
	end

	# Return the URL-version of the product's name (special chars replaced with '-'s)
	def url_name
		product_name.downcase.gsub(/[^a-z0-9\- ]+/, '').gsub(/[\s]+/, '-')
	end

	# Returns the `short_description` if available, otherwise returns the `description`. `force`
	# will ensure that even a short_description gets cut to max_length.
	def abbrev_description ( max_length = 150 , force = false)
		if short_description
			if force && (short_description.length - 3) > max_length
				"#{short_description.slice(0, max_length)}..."
			else
				short_description
			end
		else
			if (description.length - 3) > max_length
				"#{description.slice(0, max_length)}..."
			else
				description || "(no description available)"
			end
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
		# Utility method for performing a discount on a given price.
		def discount_price(base_price, discount, discount_is_abs)
			if (discount_is_abs)
				base_price - discount
			else
				base_price - ((discount * base_price).round / 100.00)
			end
		end
	end
end

# Represents a product in the store that is composed of more than one other product. Examples of this are:
# * two widgets for the price of one
# * Amazon's "buy together and save"
# * a set of clothing items that are also available individually in the store.
class CompositeProduct < Product
	has_many :components, :class_name => 'ProductComponent', :order => :position, :foreign_key => :parent_id, :dependent => :destroy

	def name
		if product_name.nil?
			case components.length
				when 0
					nil
				when 1
					components.first.child.name
				else
					a = Array.new(components)
					last = a.pop
					a.collect { |c| c.child.name }.join(', ') + ' and ' + last.child.name
			end
		else
			product_name
		end
	end

	def price
		if base_price.zero?
			Product.discount_price(components.inject(0.0) { |sum, x| sum + (discount.zero? ? x.child.price : x.child.base_price) }, discount, discount_is_abs)
		else
			Product.discount_price(base_price, discount, discount_is_abs)
		end
	end

	def weight
		base_weight.zero? ? components.inject(0.0) { |sum, x| sum + x.child.weight } : base_weight
	end

	# Adds a component to this product. You can't add a product to itself, or the universe will implode (or something equally terrifying).
	def <<(product)
		if product.is_a?(CompositeProduct) and (product.id == id || product.has_child?(self))
			nil
		else
			component = components.find(:first, :conditions => [ 'child_id = ?', product.id ])
			if component.nil?
				components.create(:parent => self, :child => product, :quantity => 1)
			else
				component.update_attribute(:quantity, component.quantity + 1)
			end
		end
	end

	# Return +true+ if this product (or one of its components) contains the given component.
	def has_child?(product)
		r = false
		components.each do |c|
			r ||= (c.child.id == product.id)
			if !r and c.child.is_a? CompositeProduct
				r ||= c.child.has_child?(product)
			end
			break unless !r
		end
		r
	end

	# Removes the given component.
	def delete_child(product)
		product = product.is_a?(Product) ? product.id : product.to_i
		components.delete(components.find_by_child_id(product))
	end

	class << self
		# Returns a list of CompositeProduct items containing a given product (useful for
		# things like "buy this item together with..." displays). The +n+ parameter can be:
		# * :+all+ - return all matching CompositeProducts
		# * :+first+ - return only the first matching CompositeProduct
		# * (a number) - return (up to) this many matching CompositeProducts
		def for_product(product, n = :all)
			p = CompositeProduct.find(:all, :joins => 'LEFT JOIN product_components ON product_components.parent_id = products.id', :conditions => ['product_components.child_id = ?', product.id], :select => 'products.*')
			case n
				when :all then p
				when :first then p.first
				else (0...n).inject([]) { |s, i| p.empty? ? s : s + [p.delete(p[rand(p.length)])] }
			end
		end
	end
end
