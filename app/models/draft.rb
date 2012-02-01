# Represents a user's Cart, stored for future use, in a primative way.
# Holds a collection of DraftItem objects representing the quantity and nature of the products
# chosen. Is NOT an Order (has no shipping etc information)

class Draft < ActiveRecord::Base
	belongs_to :user
	has_many :items, :class_name => 'DraftItem'

	# calculate the total value of the draft order
	def total
		the_total = 0
		items.each do |cur_item|
			the_total += cur_item.total
		end
		the_total
	end
end
