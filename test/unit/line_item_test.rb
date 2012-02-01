require File.dirname(__FILE__) + '/../test_helper'

class LineItemTest < Test::Unit::TestCase
	fixtures :line_items, :products

	def test_truth
		assert_kind_of LineItem, line_items(:lots_of_chicken)
	end
end
