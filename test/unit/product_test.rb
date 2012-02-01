require File.dirname(__FILE__) + '/../test_helper'

class ProductTest < Test::Unit::TestCase
	fixtures :products, :categories, :categories_products

	# Remember, if this test fails, truth fails. And the world will collapse.
	# SO ENSURE THIS TEST PASSES!
	def test_truth
		assert_kind_of Product, products(:chicken)
	end

	def test_product_code
		# check code is loaded correctly
		assert_equal 'EC2', products(:chicken).product_code

		# check code can be changed and saved
		products(:chicken).product_code = 'EC3'
		assert products(:chicken).save
		products(:chicken).reload
		assert_equal 'EC3', products(:chicken).product_code

		# check code cannot be nil
		products(:chicken).product_code = nil
		assert !products(:chicken).save
		assert_equal 1, products(:chicken).errors.count
		assert_equal 'can\'t be blank', products(:chicken).errors.on(:product_code)
	end

	def test_product_name
		# check name is loaded correctly
		assert_equal 'Exploding Chicken', products(:chicken).product_name

		# check name can be changed and saved
		products(:chicken).product_name = 'Ninja Chicken'
		assert products(:chicken).save
		products(:chicken).reload
		assert_equal 'Ninja Chicken', products(:chicken).product_name

		# check name cannot be nil
		products(:chicken).product_name = nil
		assert !products(:chicken).save
		assert_equal 1, products(:chicken).errors.count
		assert_equal 'can\'t be blank', products(:chicken).errors.on(:product_name)
	end

	def test_path
		assert_equal '/products/livestock/1-exploding-chicken.html', products(:chicken).path
		assert_equal '/products/livestock/2-homicidal-bovine.html', products(:cow).path
	end

	def test_price
		equal_var = 132000.0

		assert_equal 132000.0, products(:cow).base_price.to_s.to_f
		# ensure discounts are calculating correctly
		assert_equal 66000.0, products(:cow).price.to_s.to_f
	end
end
