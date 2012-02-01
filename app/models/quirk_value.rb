# Represents a relationship between a Product and a Quirk - is the concrete class for a Quirk
class QuirkValue < ActiveRecord::Base
	belongs_to :product
	belongs_to :quirk

	# to ensure we can only have 1 of each concrete attribute for each product
	validates_uniqueness_of :quirk_id, :scope => :product_id

	def position
		quirk.position
	end
end
