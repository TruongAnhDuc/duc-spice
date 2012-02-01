# Controller for all admin-level functions for newsletter signups. Checks to see if the currently
# logged-in user is a staff member before allowing access

class Admin::NewsletterSignupsController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Shows the list of people (email addresses) that have signed up for email newsletters. Also
	# allows an administrator to add or remove people from that list.
	def list
		@current_area = 'newsletter_signups'
		@current_menu = 'newsletter_signups'

		sort_order ||= get_sort_order("s-name", ["first_name", "last_name"])
		sort_order ||= get_sort_order("s-email", "email")
		sort_order ||= "id ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		if params[:delete] and params[:select]
			c = params[:select].keys.collect do |cur_key|
				NewsletterSignup.delete(cur_key.to_i)
			end
		end

		@signup_count = NewsletterSignup.count

		@pages = Paginator.new(self, @signup_count, items_per_page, page)

		@signups = NewsletterSignup.find(:all, :order => sort_order)
	end


	# Shows a specifically formatted version of the list of people (email addresses) that have
	# signed up for email newsletters - this list being designed to be able to be pasted directly
	# into an email application.
	def copyable
		@current_area = 'newsletter_signups'
		@current_menu = 'newsletter_signups'

		@signups = NewsletterSignup.find(:all)
	end


	# Allows an administrator to manually add people to the list that have signed up for email
	# newsletters - for example, if somebody enquires about them directly via email.
	def new
		@current_area = 'newsletter_signups'
		@current_menu = 'newsletter_signups'

		if request.post?
			@newsletter_signup = NewsletterSignup.new(params[:newsletter_signup])
			if @newsletter_signup.save
				flash[:notice] = 'Newsletter signup successfully added'

				redirect_to :action => :list
			else
				flash[:error] = 'Please enter both a name and an email address'
			end
		else
			@newsletter_signup = NewsletterSignup.new
		end
	end
end
