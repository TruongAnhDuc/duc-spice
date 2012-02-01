# This is the main controller for the public face of the site, and handles all the catalogue-type functions.
class ProductsController < ApplicationController
	before_filter :authorise


	# Display the home page of the site. If there's a file called <tt>home.rhtml</tt> in the
	# <tt>/custom/templates</tt> directory, that is used as the layout instead of the
	# default <tt>products.rhtml</tt> layout, which means your homepage can be as
	# unique as you like.
	#
	# You can also have a custom home layout if you need a totally different look for your home page
	# (which is becoming quite common).  Just put a home.rhtml in app/views/layouts.  If this is not
	# present, the "products" layout will be used instead.
	#
	# <b>Template:</b> <tt>products/home.rhtml</tt>
	def home
		@static_page = StaticPage.find_by_form_name("home")

		if File.exist? "#{RAILS_ROOT}/custom/layouts/home.rhtml"
			# We cannot specify an absolute path for the layout :/
			layout_to_use = "../../custom/layouts/home.rhtml"
		else
			layout_to_use = "products"
		end

		if File.exist? "#{RAILS_ROOT}/custom/templates/home.rhtml"
			render :file => "#{RAILS_ROOT}/custom/templates/home.rhtml", :use_full_path => false, :layout => layout_to_use
		else
			render :action => :home, :layout => layout_to_use
		end
	end


	# Displays a category page, with a list of subcategories and available products. Of course,
	# exactly <em>what</em> ends up on this page is entirely up to the template.
	#
	# Also routes product pages, because the routing is b0rk3d (it's a hard fix)
	#
	# <b>Template:</b> <tt>products/category.rhtml</tt>
	def category
		@root_cat = Category.find(1)

		# PRODUCT page
		if params[:categories] and !params[:categories].empty? and params[:categories].last.match(/\.html$/)
			product
		# CATEGORY page
		else
			if params[:categories] and !params[:categories].empty?
				@category = Category.find(:first, :conditions => [ 'path=?', @root_cat.filename + '/' + params[:categories].join('/')])
				if @category
					@subcategories = @category.children
				else
					@category = nil
					@subcategories = Category.top_level
				end
			else
				@category = @root_cat
				@subcategories = Category.top_level
			end

			# get the products/options for this category
			if @category
				if @configurator[:application][:items_per_page] and !@configurator[:application][:items_per_page][:value].to_i.zero?
					@items_per_page = @configurator[:application][:items_per_page][:value].to_i
					@page = (params[:page] || 1).to_i
					@offset = (@page - 1) * @items_per_page
					@product_count = @category.products.length
					@result_pages = Paginator.new(self, @product_count, @items_per_page, @page)
					@products = @category.products[@offset, @items_per_page]
				else
					@products = @category.products
					@items_per_page = @products.length
				end

				# should really put some conditions in here so only Option's that are used
				# in the Product's above are included.
				@options = Option.find(:all)

				# create the 'option_values' array, which is an array (indexed by Product
				# id) of arrays (indexed by Option id) of OptionValue's. Each Product will
				# incur a single DB hit (better than before) for its OptionValue's, as well
				# as the DB hit to get all the Product's, and all the Option's.
				@option_values = Array.new
				# also create the 'multi_line_options' array, which is a smaller array
				# of option values that use the MultiLineOption Option type (these are
				# excluded from the above 'option_values' array
				@multi_line_option_values = Array.new

				@bits_array = Array.new

				@products.each do |cur_product|
					@option_values[cur_product.id] = Array.new

					cur_product.product_option_values.each do |cur_product_option_value|
						cur_option_value = cur_product_option_value.option_value
						unless cur_option_value.wholesale_only?
							@options.each do |cur_option|
								if cur_option[:id] == cur_option_value[:option_id] && cur_option.class.to_s == 'MultiLineOption'
									if !@multi_line_option_values[cur_product.id]
										@multi_line_option_values[cur_product.id] = Array.new
									end

									if !@multi_line_option_values[cur_product.id][cur_option_value[:option_id]]
										@multi_line_option_values[cur_product.id][cur_option_value[:option_id]] = Array.new
									end
									@multi_line_option_values[cur_product.id][cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
								end
							end

							if !@option_values[cur_product.id][cur_option_value[:option_id]]
								@option_values[cur_product.id][cur_option_value[:option_id]] = Array.new
							end
							@option_values[cur_product.id][cur_option_value[:option_id]][cur_option_value.id] = cur_product_option_value
						end
					end

					@bits_array[cur_product[:id]] = Array.new

					@options.each do |cur_option|
						if cur_option.class.to_s == 'MultiLineOption'
							if @multi_line_option_values[cur_product[:id]] && @multi_line_option_values[cur_product[:id]][cur_option[:id]] && !@multi_line_option_values[cur_product[:id]][cur_option[:id]].empty?
								old_bits = @bits_array[cur_product[:id]].empty? ? nil : @bits_array[cur_product[:id]]
								@multi_line_option_values[cur_product[:id]][cur_option[:id]].each do |cur_multi_line_option_value|
									if cur_multi_line_option_value
										if old_bits
											old_bits.each do |cur_bits|
												cur_bits['string'] += ", #{cur_option[:name]}: <strong>#{cur_multi_line_option_value[:value]}</strong>"
												cur_bits['option_values'] << { cur_option[:id] => cur_multi_line_option_value[:value] }
												@bits_array[cur_product[:id]] << cur_bits
											end
										else
											new_bits = {
												'string' => "#{cur_option[:name]}: <strong>#{cur_multi_line_option_value[:value]}</strong>",
												'option_values' => Hash.new
											}
											new_bits['option_values'][cur_option[:id]] = cur_multi_line_option_value
											@bits_array[cur_product[:id]] << new_bits
										end
									end
								end
							end
						end
					end
				end

				if @category.meta_description && !@category.meta_description.empty?
					@meta_description = @category.meta_description
				end
				if @category.meta_keywords && !@category.meta_keywords.empty?
					@meta_keywords = @category.meta_keywords
				end
			end

			# Now that we know which category we're in, let's select a featured product.
			# This assumes that the root category is ID 1...
			@featured_products = Feature.for_category((@category.nil? ? 1 : @category), @configurator[:modules][:num_featured_products][:value])
		end
	end



	# Displays a product detail page.
	#
	# As it turns out, this method is NEVER called directly - routing all goes to the above
	# 'categories' method (*sigh*). Although that now farms out product pages to here. So
	# 'categories' effectively becomes a dispatcher.
	#
	# <b>Template:</b> <tt>products/product.rhtml</tt>
	def product
		@category = Category.find(:first, :conditions => [ 'path=?', @root_cat.filename + '/' + params[:categories].slice(0, params[:categories].length - 1).join('/')])

		# We could remove the condition to allow expired products to still be viewable on the front-end
		begin
			@product = Product.find(params[:categories].pop.split('-', 2).first.to_i, :conditions => 'available = 1 AND (expiry_date IS NULL OR expiry_date >= \'' + Date.today.to_s + '\')')
		# If the product wasn't found
		rescue ActiveRecord::RecordNotFound
			render :template => 'products/product_not_found' and return false
		end
		@page_title = @product.page_title

		# should really put some conditions in here so only Option's that are used in this
		# Product are included.
		@options = Option.find(:all)

		# create the 'option_values' array, which is an array (indexed by Option id) of
		# OptionValue's. Will incur a single DB hit (better than before) for the OptionValue's
		@option_values = Array.new
		# also create the 'multi_line_option_values' array, which is a smaller array of
		# option values that this product assotiates with that use the MultiLineOption
		# Option type (these are excluded from the above 'option_values' array
		@multi_line_option_values = Array.new

		product_option_values_array = @product.product_option_values
		product_option_values_array.each do |cur_product_option_value|
			if cur_product_option_value
				cur_option_value = cur_product_option_value.option_value
				unless cur_option_value.wholesale_only?
					@options.each do |cur_option|
						if cur_option[:id] == cur_option_value[:option_id] && cur_option.class.to_s == 'MultiLineOption'
							if !@multi_line_option_values[cur_option_value[:option_id]]
								@multi_line_option_values[cur_option_value[:option_id]] = Array.new
							end
							@multi_line_option_values[cur_option_value[:option_id]][cur_option_value.id] = cur_option_value
						end
					end

					if !@option_values[cur_option_value[:option_id]]
						@option_values[cur_option_value[:option_id]] = Array.new
					end
					@option_values[cur_option_value[:option_id]][cur_option_value.id] = cur_product_option_value
				end
			end
		end

		@bits_array = Array.new
		@options.each do |cur_option|
			if cur_option.class.to_s == 'MultiLineOption'
				if @multi_line_option_values[cur_option[:id]] && !@multi_line_option_values[cur_option[:id]].empty?
					old_bits = @bits_array.empty? ? nil : @bits_array
					@multi_line_option_values[cur_option[:id]].each do |cur_multi_line_option_value|
						if cur_multi_line_option_value
							if old_bits
								old_bits.each do |cur_bits|
									cur_bits['string'] += ', <strong>' + cur_option[:name] + '</strong>: ' + cur_multi_line_option_value[:value]
									cur_bits['option_values'] << { cur_option[:id] => cur_multi_line_option_value[:value] }
									@bits_array << cur_bits
								end
							else
								new_bits = {
									'string' => '<strong>' + cur_option[:name] + '</strong>: ' + cur_multi_line_option_value[:value],
									'option_values' => Hash.new
								}
								new_bits['option_values'][cur_option[:id]] = cur_multi_line_option_value
								@bits_array << new_bits
							end
						end
					end
				end
			end
		end

		#SNIP=cross_selling
		# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature

		# Here we find the Amazon-esque "Customers who bought this item also bought" feature.
		#
		# The conditions we use to match products that other customers bought in the same order:
		# 1. The product ID of the "other" product must not match this one
		# 2. The "other" product was not purchased at a discounted price
		# 3. The price of the "other" product is not too much different from this one (currently 50% which may be a bit much)
		# 4. The order in which the "other" product appears must be less than a certain age (configurable; 0 = no limit)
		# 5. The order in which the "other" product appears must have 'completed' or 'awaiting_shipping' status.
		# 6. The "other" product is actually available
		#
		# In testing the query seems fine time-wise (using the Kiwi Products db on avatar1), but
		# this only contains 2336 line items at the moment... I'm not sure how well this will scale
		# in a really busy site due to a self-join on the line_items table which could become quite large.
		#
		# Currently it only weights by the amount of orders that contained this product.  You can easily
		# change this to count the total quantity of the "other" product by changing the COUNT to a SUM.
		# Note that the 'amount' column is only required for sorting: P.* is all that Rails needs.
		#
		# About the "price factor":
		#   This number is a float within the range 0 to 1.  It represents a percentage by which the
		#   prices may differ, relative to the currently-viewed product.  By default it is 0.5
		#   which means the related product will have a price of between 50% and 150% of the
		#   product being viewed.  0.3 would be 70% to 130%, and so on.
		#
		# I don't think I want to try this purely with ActiveRecord.
		time_limit = @configurator[:modules][:others_bought_time_limit][:value]
		@others_also_bought = Product.find_by_sql('
			SELECT
				P.*,
				COUNT(LI1.quantity) AS amount
			FROM products AS P
				INNER JOIN line_items AS LI1
					ON LI1.product_id = P.id
				INNER JOIN line_items AS LI2
					ON LI2.order_id = LI1.order_id
				INNER JOIN orders AS O
					ON LI1.order_id = O.id
			WHERE
				LI2.product_id = ' + @product.id.to_s + '
				AND LI1.product_id <> LI2.product_id
				AND LI1.discount = 0
				AND ABS(LI1.unit_price - LI2.unit_price) / LI2.unit_price < ' + @configurator[:modules][:others_bought_price_factor][:value].to_s + '
				' + ((time_limit == 0) ? '' : (' AND DATE_SUB(NOW(), INTERVAL ' + time_limit.to_s + ' MONTH) < O.created_at')) + '
				AND (O.status = \'awaiting_shipping\' OR O.status = \'completed\')
				AND P.available = 1
			GROUP BY LI1.product_id
			ORDER BY amount DESC
			LIMIT ' + @configurator[:modules][:others_bought_list_length][:value].to_s + '
			OFFSET 0;
		')

		# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
		#/SNIP=cross_selling

		if @product.meta_description && !@product.meta_description.empty?
			@meta_description = @product.meta_description
		end
		if @product.meta_keywords && !@product.meta_keywords.empty?
			@meta_keywords = @product.meta_keywords
		end

		@can_post_review = false
		if @current_user
			existing_review = Review.find( :first, :conditions => [ "user_id = #{@current_user[:id]} AND product_id = #{@product[:id]}" ] )

			unless existing_review
				@can_post_review = true

				if request.post? and params[:review]
					@review = Review.new(params[:review])
					@review[:user_id] = @current_user[:id]
					@review[:product_id] = @product[:id]
					if @review.save
						flash[:notice] = "Review submitted"
					else
						flash[:error] = "Unable to save review"
					end
				end
			end
		end

		render :action => :product
	end


	# Shows all Products in the database, seperated only by the top-level Categories they're in.
	def products_overview
		@product_catalogue = Array.new

		@static_page = StaticPage.find_by_form_name("overview")

		top_level_cats = Category.find(:all, :conditions => [ 'parent_id = 1' ], :order => 'sequence')
		top_level_cats.each do |cur_top|
			cat_hash = { 'category' => cur_top, 'products' => Array.new }

			cur_top.products.each do |product|
				unless product.wholesale_only?
					cat_hash['products'] << product
				end
			end

			sub_cats = Category.find(:all, :conditions => [ "path LIKE ?", cur_top.path + '/%' ])
			sub_cats.each do |cur_sub|
				cur_sub.products.each do |product|
					unless product.wholesale_only?
						cat_hash['products'] << product
					end
				end
			end

			@product_catalogue << cat_hash
		end
	end


	# Performs a product search using the given criteria. If this is called
	# without any parameters, the user should be shown an "Advanced Search" page
	# with additional options for category selection (the default templates include
	# an example of this). Otherwise, a paginated list of search results is displayed
	# (the number of items per page can be changed by anyone with admin access,
	# through the "Application Settings" page.
	#
	# <b>Template:</b> <tt>products/search.rhtml</tt>
	def search
		@static_page = StaticPage.find_by_form_name("search")

		if params[:query] && params[:query] != ''
			# don't do a search on a blank search term
			page = params[:page] ? params[:page].to_i : 1
			items_per_page = 5
			offset = (page - 1) * items_per_page

			@keywords = params[:query].split
			mode = params[:mode] || 'all'
			where_parts = @keywords.collect { |k| "(products.product_name LIKE \"%#{k}%\" OR products.description LIKE \"%#{k}%\")" }
			where_clause = where_parts.join(mode == 'all' ? ' AND ' : ' OR ')

			if params[:cat] and params[:cat].is_a?(Array) and !params[:cat].empty?
				cat_parts = []
				params[:cat].each do |id|
					c = Category.find(id.to_i)
					cat_parts << ("(categories.lft >= #{c.lft} AND categories.lft <= #{c.rgt})")
				end
				where_clause += ' AND (' + cat_parts.join(' OR ') + ')'
			end
			# Filter out unavailable products
			where_clause += ' AND products.available = 1'

			@product_count = Product.count(
				where_clause,
				'LEFT JOIN categories_products ON product_id = products.id LEFT JOIN categories ON category_id = categories.id'
			)
			@result_pages = Paginator.new(self, @product_count, items_per_page, page)
			@products = Product.find(
				:all,
				:conditions => where_clause,
				:joins => 'LEFT JOIN categories_products ON product_id = products.id LEFT JOIN categories ON category_id = categories.id',
				:group => 'products.id',
				:offset => offset,
				:select => 'products.*',
				:limit => items_per_page
			)
		end
	end
end
