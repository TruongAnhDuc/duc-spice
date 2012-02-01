# Represents a product featured in a given category. Has a pointer to another Product that stores
# all the atomic data; this is basically just the Decorator Pattern at work. The product's name,
# weight, code, discount and image can all be overridden.
#
# The +weighting+ field allows weighted selection of featured products. For example, a
# FeaturedProduct with a +weighting+ of 5 should show up, on average, five times as often as a
# product with a +weighting+ of 1 (the default).
class FeaturedProduct < Product
	belongs_to :product, :foreign_key => 'featured_product_id'
	belongs_to :featured_category, :class_name => 'Category', :foreign_key => 'featured_in'
	composed_of :weighting, :class_name => 'FeaturedWeighting', :mapping => [ :featured_weighting, :weighting ]

	# URL for the product detail page for this product.
	def path
		if product.categories && product.categories.first
			'/products/' + product.categories.first.path + '/' + self.id.to_s + '-' + self.url_name + '.html'
		else
			'/products/' + self.id.to_s + '-' + self.url_name + '.html'
		end
	end

	# This stuff is based on the validation method for Product.
	def validate
		if(discount_is_abs)
			if(discount < 0.0)
				errors.add(:discount, "must be a positive number.")
			end
			if(base_price > 0 and discount > base_price)
				errors.add(:discount, "cannot be greater than the base price.")
			end
		else
			if(discount < 0.0 or discount > 100.0)
				errors.add(:discount, "must be between 0 and 100.")
			end
		end
		if(base_price < 0)
			errors.add(:base_price, "must be a positive number.")
		end
	end

	def name
		product_name || product.name
	end

	def product_code
		super || product.product_code
	end

	def description
		super || product.description
	end

	def image
		super || product.image
	end

	# This is used in the product view.  If our base price is zero we need to return the base
	# price of the product we're featuring so the javascript can apply discounts correctly.
	def raw_base_price
		base_price.zero? ? product.base_price : base_price
	end

	def price
		if base_price.zero?
			if discount.zero?
				product.price
			else
				Product.discount_price(product.base_price, discount, product.discount_is_abs)
			end
		else
			Product.discount_price(base_price, discount, product.discount_is_abs)
		end
	end

	# This isn't use at the moment as the admin screen has nowhere to set a weight for a featured product.
	# I don't see why a product would need to have a different weight when featured...
	def weight
		base_weight.zero? ? product.weight : base_weight
	end

	# Same as per raw_base_price: the view javascript needs the product's base weight so it
	# can apply option weights.  Because the featured products can't currently have their own weights,
	# we apply the product base_weight instead.
	def raw_base_weight
		product.base_weight
	end

	class << self
		# Returns one or more randomly-selected featured products for a given category,
		# according to their respective weightings.
		def for_category(category, n = 1)
			category = Category.find(category.to_i) unless category.is_a? Category

			# For the featured_all_levels feature we need to get the IDs of all the parent categories
			# all the way up to the root category.
			# I have decided to find based on the category paths which prevents us from hitting the
			# database.  I envisage that categories will rarely exceed a few levels deep...
			# The featured_product_id WHERE clause should prevent the db doing expensive text matches
			# on every product.

			path_str = '\'\''
			temp_path = ''
			first = true
			category.path.split('/').each do |p|
				temp_path += (first ? '' : '/') + p
				path_str += ',\'' + temp_path + '\''
				first = false
			end

			fp_table = Product.connection.select_all("
				SELECT
					products.id,
					products.featured_weighting AS w
					FROM products
				LEFT JOIN categories AS cat
					ON products.featured_in = cat.id
				WHERE
						featured_product_id IS NOT NULL
					AND (featured_until IS NULL OR (featured_until + INTERVAL 1 DAY) >= NOW())
					AND (
							featured_in = #{category.id}
						OR (
								featured_all_levels = 1
							AND cat.path IN ( #{path_str} )
						)
					)
			")
			fp = fp_table.collect { |x| [ x['id'].to_i ] * (x['w'].nil? ? 1 : x['w'].to_i) }.flatten

			products = []
			while products.length < n and !fp.empty?
				i = fp[rand(fp.length)]
				products << Product.find(i)
				fp.delete(i)
			end

			products
		end
	end
end

# Accesses the +weighting+ of a FeaturedProduct.
class FeaturedWeighting
	attr_reader :weight

	def initialize(weight)
		@weight = weight
	end

	def to_i
		@weight
	end

	def to_s
		@weight.to_s
	end

	class << self
		def range
			[1..5]
		end
	end
end

class Numeric #:nodoc:
	def weighting #:nodoc:
		FeaturedWeighting.new(self)
	end
end
