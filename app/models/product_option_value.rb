# Represents a relationship between a Product and an Option's concrete class (an OptionValue).
class ProductOptionValue < ActiveRecord::Base
	belongs_to :product
	belongs_to :option_value
	acts_as_list :order => 'position', :scope => 'product_id'

	# to ensure we can only have 1 of each concrete option for each product
	validates_uniqueness_of :option_value_id, :scope => :product_id

	def default_value
		option.default_value
	end
end
