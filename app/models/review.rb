# Represents a User's opinion about a Product
# Holds both a textual 'review' as well as a numeric 'rating'. Can be moderated etc as well.

class Review < ActiveRecord::Base
	belongs_to :user
	belongs_to :product

	validates_uniqueness_of :product_id, :scope => :user_id
end
