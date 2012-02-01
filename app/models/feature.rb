# Represents a product featured in a given category, static page or in the layout. The product's
# description can be overridden.
#
# The +weighting+ field allows weighted selection of features. For example, a Feature with a
# +weighting+ of 5 should show up, on average, five times as often as a product with a +weighting+
# of 1 (the default).
#
# Note that at some point the 'in layout' featuring will probably need to be extended to support
# URL-matching. The Category featuring is maintained so Features can behave similarly to the
# FeaturedProducts they replace. The Static Page featuring is for new behavious - specifically, so
# people can feature products on the home page.
class Feature < ActiveRecord::Base
	belongs_to :product
	has_and_belongs_to_many :categories, :join_table => 'categories_features'
	has_and_belongs_to_many :static_pages, :join_table => 'features_static_pages'

	def description
		super || product.description
	end

	class << self
		def pick_out_rand(product_id_weighting_array, n)
			fp = product_id_weighting_array.collect { |x| [ x['product_id'].to_i ] * (x['weighting'].nil? ? 1 : x['weighting'].to_i) }.flatten

			products = []
			while products.length < n and !fp.empty?
				i = fp[rand(fp.length)]
				the_product = Product.find(i)

				# find the feature's description (that could over-ride the product's)
				the_description = nil
				product_id_weighting_array.each do |cur_hit|
					if cur_hit["product_id"].to_i == i
						the_description = cur_hit["description"]
					end
				end
				the_description ||= the_product[:short_description]
				the_product[:short_description] = the_description

				products << the_product
				fp.delete(i)
			end

			products
		end

		# Returns one or more randomly-selected featured products for a given category,
		# according to their respective weightings.
		def for_category (category, n = 1)
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

			fp_table = Feature.connection.select_all("
				SELECT
					features.description,
					features.product_id,
					features.weighting
					FROM features
				LEFT JOIN products
					ON products.id = features.product_id
				LEFT JOIN categories_features AS cat_feat
					ON features.id = cat_feat.feature_id
				LEFT JOIN categories AS cat
					ON cat_feat.category_id = cat.id
				WHERE
					(features.until IS NULL OR (features.until + INTERVAL 1 DAY) >= NOW())
					AND (
						cat_feat.category_id = #{category.id}
						OR (
							features.all_levels = 1
							AND cat.path IN ( #{path_str} )
						)
					)
					AND (products.available = 1)
			")

			pick_out_rand(fp_table, n)
		end

		# Returns one or more randomly-selected featured products for a given static page,
		# according to their respective weightings.
		def for_static_page (static_page, n = 1)
			fp_table = Feature.connection.select_all("
				SELECT
					features.description,
					features.product_id,
					features.weighting
					FROM features
				LEFT JOIN products
					ON products.id = features.product_id
				LEFT JOIN features_static_pages AS feat_stat
					ON features.id = feat_stat.feature_id
				LEFT JOIN static_pages AS stat
					ON feat_stat.static_page_id = stat.id
				WHERE
					(features.until IS NULL OR (features.until + INTERVAL 1 DAY) >= NOW())
					AND (feat_stat.static_page_id = #{static_page})
					AND (products.available = 1)
			")

			pick_out_rand(fp_table, n)
		end

		# Returns one or more randomly-selected featured products for the layout, according to
		# their respective weightings.
		def for_layout (n = 1)
			fp_table = Feature.connection.select_all("
				SELECT
					features.description,
					features.product_id,
					features.weighting
					FROM features
				LEFT JOIN products
					ON products.id = features.product_id
				WHERE
					(features.until IS NULL OR (features.until + INTERVAL 1 DAY) >= NOW())
					AND (features.in_layout = 1)
					AND (products.available = 1)
			")

			pick_out_rand(fp_table, n)
		end
	end
end
