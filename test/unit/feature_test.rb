require File.dirname(__FILE__) + '/../test_helper'

# Tests of Features (advertisements of a Product)
class FeatureTest < Test::Unit::TestCase
	fixtures :products, :categories, :categories_features, :features, :static_pages, :features_static_pages

	# test that the 'for_category' method works
	def test_feature_for_category
		features = Feature.for_category(categories(:root).id, 99)

		assert_equal(2, features.length)
		assert_equal(true, features.include?(products(:persian)))
		assert_equal(true, features.include?(products(:cow2)))

		features = Feature.for_category(categories(:livestock).id, 99)

		assert_equal(1, features.length)
		assert_equal(true, features.include?(products(:optioner)))

		features = Feature.for_category(categories(:dogs).id, 99)

		assert_equal(3, features.length)
		assert_equal(true, features.include?(products(:cow2)))
		assert_equal(true, features.include?(products(:cow3)))
		assert_equal(true, features.include?(products(:optioner))) # inherited from livestock

		features = Feature.for_category(categories(:dogs).id)

		assert_equal(1, features.length)

		# check that the correct number is given when the number to return is < the number of
		# results found in the db
		features = Feature.for_category(categories(:dogs).id, 1)

		assert_equal(1, features.length)

		features = Feature.for_category(categories(:dogs).id)

		assert_equal(1, features.length)

		# check a blank return
		features = Feature.for_category(categories(:utilities).id, 1)

		assert_equal(0, features.length)
	end

	# test that the 'for_static_page' method works - basically the same as the 'for_category'
	# method above, but for static pages
	def test_feature_for_static_page
		features = Feature.for_static_page(static_pages(:home).id, 99)

		assert_equal(2, features.length)
		assert_equal(true, features.include?(products(:optioner)))
		assert_equal(true, features.include?(products(:cow2)))

		features = Feature.for_static_page(static_pages(:aboutus).id, 99)

		assert_equal(1, features.length)
		assert_equal(true, features.include?(products(:cow3)))

		# check that the correct number is given when the number to return is < the number of
		# results found in the db
		features = Feature.for_static_page(static_pages(:home).id, 1)

		assert_equal(1, features.length)

		features = Feature.for_static_page(static_pages(:home).id)

		assert_equal(1, features.length)

		# check a blank return
		features = Feature.for_static_page(static_pages(:contactus).id, 1)

		assert_equal(0, features.length)
	end

	# test that the 'for_layout' method works - similar to the 'for_category' method above, but
	# for the layout
	def test_feature_for_layout
		features = Feature.for_layout(99)

		assert_equal(2, features.length)
		assert_equal(true, features.include?(products(:optioner)))
		assert_equal(true, features.include?(products(:cow3)))

		# check that the correct number is given when the number to return is < the number of
		# results found in the db
		features = Feature.for_layout(1)

		assert_equal(1, features.length)

		features = Feature.for_layout

		assert_equal(1, features.length)
	end

	# test that a description given to a feature overrides (if provided) the products description
	def test_overriding_description
		# first, a feature with no description assigned
		features = Feature.for_static_page(static_pages(:aboutus).id)

		assert_equal("Short description", features.first[:short_description])

		# now, a feature with a description to override
		features = Feature.for_category(categories(:livestock).id)

		assert_equal("Different description", features.first[:short_description])
	end
end
