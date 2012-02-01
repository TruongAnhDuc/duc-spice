# LEGACY!
# this class exists only in v1.0 of RocketCart
# Represents a relationship between a product and an Option.
class ProductOption < ActiveRecord::Base
	belongs_to :product
	belongs_to :option
	acts_as_list :order => 'position', :scope => 'product_id'
	serialize :values

	def default_value
		option.default_value
	end
end
