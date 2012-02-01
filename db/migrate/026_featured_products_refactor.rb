# This migration changes the database schema by refactoring all the `featured_?` fields out of the
# `products` table, and creating a new `features` table for them. This table is then assotiated
# to both the `static_pages` table and the `categories` table through join tables.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class FeaturedProductsRefactor < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

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

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		# add the new tables
		create_table :features do |new_table|
			new_table.column :product_id, :integer, :null => false, :default => 0
			new_table.column :description, :text
			new_table.column :weighting, :integer, :null => false, :default => 0
			new_table.column :all_levels, :boolean
			new_table.column :until, :date
			new_table.column :in_layout, :boolean
		end
		add_index :features, [:product_id]

		create_table :categories_features, :id => false do |new_table|
			new_table.column :category_id, :integer, :null => false, :default => 0
			new_table.column :feature_id, :integer, :null => false, :default => 0
		end
		add_index :categories_features, [:category_id, :feature_id], :unique

		create_table :features_static_pages, :id => false do |new_table|
			new_table.column :feature_id, :integer, :null => false, :default => 0
			new_table.column :static_page_id, :integer, :null => false, :default => 0
		end
		add_index :features_static_pages, [:feature_id, :static_page_id], :unique

		# now we convert old FeaturedProducts data over to the new schema
		@all_features = FeaturedProduct.find(:all)
		@all_features.each do |cur_feature|
			new_feature = Feature.new (
				:product_id => cur_feature[:featured_product_id],
				:weighting => cur_feature[:featured_weighting] ? cur_feature[:featured_weighting] : 1,
				:all_levels => cur_feature[:featured_all_levels],
				:until => cur_feature[:featured_until],
				:in_layout => false
			)
			new_feature.save

			new_feature.categories << Category.find(cur_feature[:featured_in])
			new_feature.save
		end

		# clean up the old Featured Products
		FeaturedProduct.delete(:all)

		# remove the old schema rows
		remove_column :products, :type
		remove_column :products, :featured_in
		remove_column :products, :featured_product_id
		remove_column :products, :featured_weighting
		remove_column :products, :featured_all_levels

		puts 'Migration from schema 25 -> 26 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		# add the old schema rows back in
		add_column :products, :type, :string, :limit => 32
		add_column :products, :featured_in, :integer
		add_column :products, :featured_product_id, :integer
		add_column :products, :featured_weighting, :integer
		add_column :products, :featured_all_levels, :integer
		add_column :products, :featured_until, :date

		# now we convert new Features data over to the old schema
		@all_features = Feature.find(:all)
		@all_features.each do |cur_feature|
			if cur_feature.categories && !cur_feature.categories.empty?
				old_category_id = cur_feature.categories.first[:id]

				new_featured_product = FeaturedProduct.new (
					:featured_in => old_category_id,
					:featured_product_id => cur_feature[:product_id],
					:featured_weighting => cur_feature[:weighting],
					:featured_all_levels => cur_feature[:all_levels] ? 1 : 0,
					:featured_until => cur_feature[:until]
				)
				new_featured_product.save
			end
		end

		# clean up the new Features
		Feature.delete(:all)

		# remove the new tables
		drop_table :features

		drop_table :categories_features

		drop_table :features_static_pages

		puts 'Migration from schema 26 -> 25 complete'
	end
end
