# Controller for all admin-level functions for reviews and their moderation. Checks to see if the currently
# logged-in user is a staff member before allowing access

class Admin::ReviewsController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Shows the list of reviews that have been submitted by Users.
	def list
		@current_area = "reviews"
		@current_menu = "reviews"

		sort_order ||= get_sort_order("s-product", "products.product_name")
		sort_order ||= get_sort_order("s-rating", "rating")
		sort_order ||= get_sort_order("s-user", ["users.first_name", "users.last_name"])
		sort_order ||= get_sort_order("s-shown", "allowed")
		sort_order ||= "reviews.id DESC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		@reviews_count = Review.count()

		@pages = Paginator.new(self, @reviews_count, items_per_page, page)

		@reviews = Review.find(:all, :include => [:product, :user], :order => sort_order, :offset => offset, :limit => items_per_page)
	end


	# Allows an administrator to hide, show or edit the comments for a review (moderate)
	def edit
		@current_area = "reviews"
		@current_menu = "reviews"

		if request.post?
			@review = Review.find(params[:id].to_i)

			flash_message = ""
			if params[:show] == "Show"
				@review[:allowed] = "y"
				flash_message = "The review of #{@review.product} by #{@review.user} will now be visible to shoppers"
			elsif params[:hide] == "Hide"
				@review[:allowed] = "n"
				flash_message = "The review of #{@review.product} by #{@review.user} will now be hidden from shoppers"
			elsif params[:edit] == "Edit"
				@review[:comments] = params[:review][:comments]
				flash_message = "Comments in the review of #{@review.product} by #{@review.user} edited"
			end

			if @review.save
				flash[:notice] = flash_message
				redirect_to :action => :list
			else
				flash[:error] = "Unable to save moderation"
			end
		else
			@review = Review.find(params[:id].to_i)
		end
	end

	# Allows an administrator to manually add a review.
	#
	# TODO: Dummy users should be able to be created - allowing reviews recieved via non-
	# electronic channels to be added (e.g. a Rocket Cart account isn't needed)
	def new
		if request.post?
			@review = Review.new(params[:review])
			# if you're adding it manually, then you want it shown
			@review[:allowed] = "y"

			unless @review.save
				flash[:error] = "Unable to save review"
			end
			redirect_to :action => :list
		end

		@products_by_category = Category.all.collect { |c| { :name => c.name, :id => c.id, :products => c.products } }

		all_users = User.find(
			:all,
			:order => "users.first_name ASC, users.last_name ASC",
			:select => "users.id, users.user_level, users.first_name, users.last_name, users.email"
		)
		@admins = Array.new
		@staff = Array.new
		@customers = Array.new
		all_users.each do |cur_user|
			userhash = { :id => cur_user[:id], :name => "#{cur_user[:first_name]} #{cur_user[:last_name]}" }

			case cur_user[:user_level]
				when 0
					@customers << userhash
				when 1
					@staff << userhash
				else
					@admins << userhash
			end
		end
	end
end
