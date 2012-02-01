# Represents a class of Product - a set of Products that have similar additional information
# assotiated with them (eg: books - ISBN/publisher, houses - bedrooms/bathrooms).
class ProductType < ActiveRecord::Base
	has_many :products
	has_many :quirks, :order => :position

	def to_s
		name
	end
end
