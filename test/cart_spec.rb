require 'ActiveRecord'

require '../app/models/cart.rb'
require '../app/models/product.rb'

context 'A new cart' do
	setup do
		@cart = Cart.new
	end

	specify 'should be empty' do
		@cart.items.should_be_empty
	end

	specify 'should have 1 item after adding an item' do
		@cart.add_product 1
		@cart.items.should_not_be_empty
		@cart.items.size.should_equal 1
	end
end
