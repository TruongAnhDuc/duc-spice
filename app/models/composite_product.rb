# Represents a product in the store that is composed of more than one other product. Examples of this are:
# * two widgets for the price of one
# * Amazon's "buy together and save"
# * a set of clothing items that are also available individually in the store.
class CompositeProduct < Product
	has_many :components, :class_name => 'ProductComponent', :order => :position, :foreign_key => :parent_id, :dependent => :destroy

	def name
		if product_name.nil?
			case components.length
				when 0
					nil
				when 1
					components.first.child.name
				else
					a = Array.new(components)
					last = a.pop
					a.collect { |c| c.child.name }.join(', ') + ' and ' + last.child.name
			end
		else
			product_name
		end
	end

	def price
		if base_price.zero?
			Product.discount_price(components.inject(0.0) { |sum, x| sum + (discount.zero? ? x.child.price : x.child.base_price) }, discount)
		else
			Product.discount_price(base_price, discount)
		end
	end

	def weight
		base_weight.zero? ? components.inject(0.0) { |sum, x| sum + x.child.weight } : base_weight
	end

	# Adds a component to this product. You can't add a product to itself, or the universe will implode (or something equally terrifying).
	def <<(product)
		if product.is_a?(CompositeProduct) and (product.id == id || product.has_child?(self))
			nil
		else
			component = components.find(:first, :conditions => [ 'child_id = ?', product.id ])
			if component.nil?
				components.create(:parent => self, :child => product, :quantity => 1)
			else
				component.update_attribute(:quantity, component.quantity + 1)
			end
		end
	end

	# Return +true+ if this product (or one of its components) contains the given component.
	def has_child?(product)
		r = false
		components.each do |c|
			r ||= (c.child.id == product.id)
			if !r and c.child.is_a? CompositeProduct
				r ||= c.child.has_child?(product)
			end
			break unless !r
		end
		r
	end

	# Removes the given component.
	def delete_child(product)
		product = product.is_a?(Product) ? product.id : product.to_i
		components.delete(components.find_by_child_id(product))
	end

	class << self
		# Returns a list of CompositeProduct items containing a given product (useful for
		# things like "buy this item together with..." displays). The +n+ parameter can be:
		# * :+all+ - return all matching CompositeProducts
		# * :+first+ - return only the first matching CompositeProduct
		# * (a number) - return (up to) this many matching CompositeProducts
		def for_product(product, n = :all)
			p = CompositeProduct.find(:all, :joins => 'LEFT JOIN product_components ON product_components.parent_id = products.id', :conditions => ['product_components.child_id = ?', product.id], :select => 'products.*')
			case n
				when :all then p
				when :first then p.first
				else (0...n).inject([]) { |s, i| p.empty? ? s : s + [p.delete(p[rand(p.length)])] }
			end
		end
	end
end
