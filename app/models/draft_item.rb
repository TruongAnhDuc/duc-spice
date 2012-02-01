# Represents a Product chosen for a draft order (Draft).

class DraftItem < ActiveRecord::Base
	belongs_to :draft
	belongs_to :product
	belongs_to :option_value
	# yes, has_ONE - hardcoded for SpiceTrader cos I need to save time. This isn't meant to be a
	# generalizable class

	# assumes a wholesale_cost purchase
	def total
		the_cost = product[:wholesale_base_price] + option_value[:wholesale_extra_cost]
		the_discount = product[:discount]
		abs_discount = product[:discount_is_abs]

		multiplier = draft.priced ? 1.0 : 1.1

		Product.discount_price(the_cost, the_discount, abs_discount) * quantity * multiplier
	end
end
