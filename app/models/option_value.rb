# Represents a value for an Option.

class OptionValue < ActiveRecord::Base
	belongs_to :option

# cannot use HaBtM when the join table has attributes - need to use a join Model rather than just a
# join Table
#	has_and_belongs_to_many :products, :join_table => 'product_option_values', :order => "id"
	has_many :product_option_values, :dependent => :destroy
	has_many :products, :through => :product_option_values

	has_many :line_item_option_values
	has_many :line_items , :through => :line_item_option_values

	acts_as_list :order => 'position', :scope => 'option_id'
end
