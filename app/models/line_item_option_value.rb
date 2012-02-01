# Represents a relationship between a LineItem and an Option's concrete class (an OptionValue).
class LineItemOptionValue < ActiveRecord::Base
	belongs_to :line_item
	belongs_to :option_value

	# to ensure we can only have 1 of each concrete option for each line_item
	validates_uniqueness_of :option_value_id, :scope => :line_item_id
end
