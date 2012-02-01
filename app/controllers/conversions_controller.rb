# Contains actions and functions for converting prices
class ConversionsController < ApplicationController
	layout nil

	before_filter :authorise


	# Convert a price to a given currency.
	#
	# This will mostly be called via AJAX when the user does an on-the-fly currency conversion
	# (see http://www.kiwiproducts.co.nz/ for an example of this).
	def price
		if params[:amount]
			amount = params[:amount].match(/[0-9]+(\.[0-9]+)?/).to_s.to_f
		else
			amount = 0
		end
		render :text => @currency.format(amount)
	end


	# Convert prices to a given currency.
	#
	# This will be called via AJAX when the user does an on-the-fly currency conversion
	# (see http://www.kiwiproducts.co.nz/ for an example of this).
	def prices
		if params[:products]
			product_ids = params[:products].split(',')
			if product_ids
				product_ids.each { |cur_id| cur_id = cur_id.to_i }
				ids = product_ids.join(',')

				@products = Product.find(:all, :conditions => [ 'id IN(' + ids + ')' ])

				if @products
					# create the 'option_values' array, which is an array (indexed by Product
					# id) of arrays (indexed by Option id) of OptionValue's. Each Product will
					# incur a single DB hit (better than before) for its OptionValue's, as well
					# as the DB hit to get all the Product's.
					@option_values = Array.new
					@products.each do |cur_product|
						@option_values[cur_product.id] = Array.new

						cur_product.option_values.each do |cur_option_value|
							if !@option_values[cur_product.id][cur_option_value[:option_id]]
								@option_values[cur_product.id][cur_option_value[:option_id]] = Array.new
							end
							@option_values[cur_product.id][cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
						end
					end
				end
			end
		end
	end


	# Convert prices to a given currency. Used in the 'view cart' area of the site, so just
	# converts the prices for all items in the cart
	#
	# This will be called via AJAX when the user does an on-the-fly currency conversion
	# (see http://www.kiwiproducts.co.nz/ for an example of this).
	def prices_cart
		@cart = find_cart

		@items = @cart.items

		# create the 'option_values' array, which is an array (indexed by item id) of arrays
		# (indexed by Option id) of OptionValue's. Each Product will incur a single DB hit
		# (better than before) for its OptionValue's, as well as the DB hit to get all the
		# Product's.
		@option_values = Array.new
		@items.each_with_index do |cur_item, i|
			@option_values[i] = Array.new

			cur_item.option_values.each do |cur_option_value|
				if !@option_values[i][cur_option_value[:option_id]]
					@option_values[i][cur_option_value[:option_id]] = Array.new
				end
				@option_values[i][cur_option_value[:option_id]][cur_option_value[:id]] = cur_option_value
			end
		end
	end
end
