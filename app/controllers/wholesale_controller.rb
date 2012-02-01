# Handles the wholesale order forms, as well as providing several features for wholesale customers
# including viewing their draft orders and logging in
class WholesaleController < ApplicationController
	# Use the main site layout for cart functions too
	layout "products", :except => [ :draft_printable ]
	helper :admin

	# Require the user to be registered and logged in before checking out.
	before_filter :authorise
	before_filter :require_authorisation_wholesale, :except => :login

	# ensure that the currently logged in user is a wholesale customer
	def require_authorisation_wholesale
		if !session[:user_id] || @current_user.permissions < :user || !@current_user[:sees_wholesale]
			session[:jump_to] = request.parameters
			redirect_to(:action => :login) and return false
		end
	end


	# homepage for the wholesale area - links and informs
	def index
	end


	# Show a login page. This particular login page also handles applying for a wholesale account
	#
	# <b>Template:</b> <tt>wholesale/login.rhtml</tt>
	def login
		if @current_user && @current_user[:sees_wholesale] && @current_user[:active]
			redirect_to :action => :index
		else
			if @current_user
				if params[:apply]
					user_account = User.find(@current_user[:id])
					user_account[:wholesale_application] = "p"
					user_account.save

					# send appropriate email
					Postman.deliver_wholesale_application(@configurator, user_account)

					@thank_you = true
				end
			else
				if params[:apply] && params[:user]
					@user = User.find_by_email(params[:user][:email])

					if @user
						@user[:wholesale_application] = "p"
					else
						@user = User.new(params[:user])
						@user.hash_algorithm = User.hash_algorithm_to_i(@configurator[:application][:password_hashing][:value])

						generated_password = gen_pass(10)
						@user.password = generated_password
						@user.password_confirmation = generated_password

						@user[:wholesale_application] = "p"
					end

					if @user.orders.empty?
						new_order = Order.new

						@billing_address = Address.new(params[:billing_address])
						@delivery_address = Address.new(params[:delivery_address])

						new_order[:status] = "completed"
						new_order[:shipping_email] = @user[:email]
					else
						new_order = false
					end

					User.transaction do
						@user.save!

						if new_order
							Order.transaction do
								new_order.user = @user

								@billing_address.save!
								@delivery_address.save!

								new_order.billing_address = @billing_address
								new_order.delivery_address = @delivery_address

								new_order.save!
							end
						end

						# send appropriate email
						Postman.deliver_wholesale_application(@configurator, @user)

						@thank_you = true
					end
				else
					@user = User.new
				end
			end
		end
	rescue ActiveRecord::RecordInvalid => e
		if new_order
			@billing_address.valid?
			@delivery_address.valid?
		end

		@thank_you = false
	end

	# displays an order form for all the retail products and their product options (those that
	# don't have a wholesale-only flag set)
	def retail_order_form
		if (params[:order] && !params[:order].empty?)
			@cart = find_cart

			if params["non-priced"] and params["non-priced"].to_i == 1
				@cart.priced = 0
			else
				@cart.priced = 1
			end

			params[:qty].each_pair do |prod_ov_ids, cur_qty|
				if cur_qty && !cur_qty.empty? && cur_qty.to_i > 0
					option_values = []

					bits = prod_ov_ids.split("_")

					product = Product.find(bits[0])

					if bits.length > 1
						bits.each_with_index do |cur_bit, i|
							if i > 0
								option_values << cur_bit.to_i
							end
						end
					end

					@cart.add_product(product, cur_qty, option_values, true)
				end
			end

			redirect_to :controller => :cart, :action => :checkout
		elsif (params[:draft] && !params[:draft].empty?)
			draft_order = Draft.new
			draft_order.user = @current_user

			params[:qty].each_pair do |prod_ov_ids, cur_qty|
				if cur_qty && !cur_qty.empty? && cur_qty.to_i > 0
					bits = prod_ov_ids.split("_")

					cur_item = DraftItem.new
					cur_item[:product_id] = bits[0]
					cur_item[:option_value_id] = bits[1]
					cur_item[:quantity] = cur_qty

					draft_order.items << cur_item
				end
			end

			if params["non-priced"] and params["non-priced"].to_i == 1
				draft_order[:priced] = 0
			end

			draft_order.save

			flash[:notice] = "Order saved as draft ##{draft_order.id}"
			redirect_to :action => :drafts
		end

		# so prices always appear in NZD
		@currency = Currency.find(:first)

		@products = Product.find(:all, :conditions => [ "products.wholesale_only=false AND option_values.wholesale_only=false" ], :include => [ :option_values ])

		# sorted by cat, product name
		@products.sort! do |a, b|
			a_cat = nil
			b_cat = nil

			if a.categories.first[:parent_id] == 1
				a_cat = a.categories.first
			elsif a.categories.first.parent[:parent_id] == 1
				a_cat = a.categories.first.parent
			elsif a.categories.first.parent.parent[:parent_id] == 1
				a_cat = a.categories.first.parent.parent
			elsif a.categories.first.parent.parent.parent[:parent_id] == 1
				a_cat = a.categories.first.parent.parent.parent
			end

			if b.categories.first[:parent_id] == 1
				b_cat = b.categories.first
			elsif b.categories.first.parent[:parent_id] == 1
				b_cat = b.categories.first.parent
			elsif b.categories.first.parent.parent[:parent_id] == 1
				b_cat = b.categories.first.parent.parent
			elsif b.categories.first.parent.parent.parent[:parent_id] == 1
				b_cat = b.categories.first.parent.parent.parent
			end

			if a_cat == b_cat
				a[:product_name] <=> b[:product_name]
			else
				a_cat[:sequence] <=> b_cat[:sequence]
			end
		end

		@products.each do |cur_product|
			cur_product.option_values.sort! do |a, b|
				a[:extra_cost] <=> b[:extra_cost]
			end
		end
	end

	# displays an order form for all the wholesale-ONLY products and their product options (those
	# that have a wholesale-ONLY flag set)
	def wholesale_order_form
		if (params[:order] && !params[:order].empty?)
			@cart = find_cart
			@cart.priced = 1

			params[:qty].each_pair do |prod_ov_ids, cur_qty|
				if cur_qty && !cur_qty.empty? && cur_qty.to_i > 0
					option_values = []

					bits = prod_ov_ids.split("_")

					product = Product.find(bits[0])

					if bits.length > 1
						bits.each_with_index do |cur_bit, i|
							if i > 0
								option_values << cur_bit.to_i
							end
						end
					end

					@cart.add_product(product, cur_qty, option_values, true)
				end
			end

			redirect_to :controller => :cart, :action => :checkout
		elsif (params[:draft] && !params[:draft].empty?)
			draft_order = Draft.new
			draft_order.user = @current_user

			params[:qty].each_pair do |prod_ov_ids, cur_qty|
				if cur_qty && !cur_qty.empty? && cur_qty.to_i > 0
					bits = prod_ov_ids.split("_")

					cur_item = DraftItem.new
					cur_item[:product_id] = bits[0]
					cur_item[:option_value_id] = bits[1]
					cur_item[:quantity] = cur_qty

					draft_order.items << cur_item
				end
			end

			draft_order.save

			flash[:notice] = "Order saved as draft ##{draft_order.id}"
			redirect_to :action => :drafts
		end

		# so prices always appear in NZD
		@currency = Currency.find(:first)

		@products = Product.find(:all, :conditions => [ "products.wholesale_only=true OR option_values.wholesale_only=true" ], :include => [ :option_values ])

		# sorted by cat, product name
		@products.sort! do |a, b|
			a_cat = nil
			b_cat = nil

			# D'oh... if a or b don't belong to any categories (which is a feature of v1.4) then we get crashes.
			if a.categories.length == 0 || b.categories.length == 0
				(a.categories.length == 0) <=> (b.categories.length == 0)
			end

			if a.categories.first[:parent_id] == 1
				a_cat = a.categories.first
			elsif a.categories.first.parent[:parent_id] == 1
				a_cat = a.categories.first.parent
			elsif a.categories.first.parent.parent[:parent_id] == 1
				a_cat = a.categories.first.parent.parent
			elsif a.categories.first.parent.parent.parent[:parent_id] == 1
				a_cat = a.categories.first.parent.parent.parent
			end

			if b.categories.first[:parent_id] == 1
				b_cat = b.categories.first
			elsif b.categories.first.parent[:parent_id] == 1
				b_cat = b.categories.first.parent
			elsif b.categories.first.parent.parent[:parent_id] == 1
				b_cat = b.categories.first.parent.parent
			elsif b.categories.first.parent.parent.parent[:parent_id] == 1
				b_cat = b.categories.first.parent.parent.parent
			end

			if a_cat == b_cat
				a[:product_name] <=> b[:product_name]
			else
				a_cat[:sequence] <=> b_cat[:sequence]
			end
		end

		@products.each do |cur_product|
			cur_product.option_values.sort! do |a, b|
				a[:wholesale_extra_cost] <=> b[:wholesale_extra_cost]
			end
		end
	end

	# show a list of draft orders for the current user, allowing them to view them
	def drafts
		# so prices always appear in NZD
		@currency = Currency.find(:first)

		@drafts = Draft.find(:all, :conditions => [ "user_id = #{@current_user[:id]}" ])
	end

	# show a specified draft order for the current user, allowing them to delete or confirm it
	def draft
		# so prices always appear in NZD
		@currency = Currency.find(:first)

		@draft = Draft.find(params[:id].to_i, :include => :items)

		unless @draft and (@draft[:user_id] == @current_user[:id])
			flash[:error] = "Bad Order ID #"
			redirect_to :action => :drafts
			return false
		end

		@multiplier = 1.0
		unless @draft[:priced] == 1
			@multiplier = 1.1
		end

		if params[:confirm] && !params[:confirm].empty?
			@cart = find_cart
			@cart.priced = @draft.priced

			@draft.items.each do |cur_item|
				@cart.add_product(cur_item.product, cur_item[:quantity], [cur_item.option_value], true)
			end

			Draft.delete(@draft.id)
			redirect_to :controller => :cart, :action => :checkout
			return false
		elsif params[:delete] && !params[:delete].empty?
			Draft.delete(@draft.id)
			redirect_to :action => :drafts
			return false
		end
	end

	# show a specified draft order for the current user in a printable form
	def draft_printable
		# so prices always appear in NZD
		@currency = Currency.find(:first)

		@draft = Draft.find(params[:id].to_i, :include => :items)

		unless @draft and (@draft[:user_id] == @current_user[:id])
			flash[:error] = "Bad Order ID #"
			redirect_to :action => :drafts
			return false
		end

		most_recent_order = @current_user.orders.find(:first, :order => 'created_at DESC')
		if most_recent_order
			if most_recent_order.delivery_address
				@delivery_address = most_recent_order.delivery_address
			else
				@delivery_address = most_recent_order.billing_address
			end
		end

		render(:layout => "printable")
	end
end
