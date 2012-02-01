# Represents the parent/child relationship central to the operation of CompositeProduct.
class ProductComponent < ActiveRecord::Base
	belongs_to :parent, :class_name => 'Product', :foreign_key => 'parent_id'
	belongs_to :child, :class_name => 'Product', :foreign_key => 'child_id'
	acts_as_list :scope => :parent
end
