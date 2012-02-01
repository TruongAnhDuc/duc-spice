# Main application controller. Contains functions for logging in and out, as well as session management and currency selection.
#
# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.
class ApplicationController < ActionController::Base
	before_filter :get_preferred_currency
	before_filter :configuration


	def configuration
		@configurator = ConfigReader.new('../config/rocketcart.yml')
		@design_config = ConfigReader.new('../config/design.yml')
		@modules = ConfigReader.new('../config/modules.yml')

		@ROCKETCARTDIR = @configurator[:application][:directory][:value]
	end


	# Default method for checking if a user is trying to log in or out, or if there is an active
	# login session.
	def authorise
		if params[:login] and params[:email] and params[:password]
			email = params[:email]
			# First we need to retrieve the correct hashing algorithm.  Yes I know this could be refactored
			# to put an authenticate method into the User model but I'm in a hurry :P
			user_temp = User.find(:first, :conditions => [ 'email = ?', email ])
			if user_temp
				hashed_password = User.hash_password(params[:password], user_temp.hash_algorithm)
				user = User.find(:first, :conditions => [ 'email = ? and hashed_password = ?', email, hashed_password ])
				if user
					session[:user_id] = user.id
					flash.now[:notice] = "Welcome back, #{user}!"
					if session[:jump_to]
						jump_to = session[:jump_to]
						session[:jump_to] = nil
						redirect_to jump_to
					end
				else
					flash.now[:notice] = 'Invalid email address or password'
				end
			else
				flash.now[:notice] = 'Invalid email address or password'
			end
		elsif params[:logout]
			session[:user_id] = nil
			flash[:notice] = 'You have been logged out.'
			redirect_to(request.request_uri.sub(/\?(.*)$/, '')) and return false
		end

		@request_uri = request.request_uri
		@current_user = session[:user_id] ? User.find(session[:user_id]) : nil
	end


	# Filter for actions that require login to proceed (for example, checking out).
	# Use this filter by putting something like this at the start of your controller:
	#
	#   	before_filter :require_authorisation, :only => :checkout
	#
	# Redirects to an action called +login+ if the current user isn't logged in, so make
	# sure you either have a <tt>login.rhtml</tt> template set up for that controller,
	# or override the +login+ method to render something different. The user <em>must</em>
	# be able to log in from this page.
	def require_authorisation
		if !session[:user_id]
			session[:jump_to] = request.parameters
			redirect_to(:controller => :admin, :action => :login) and return false
		end
	end


	# Dummy method to make sure <tt><em>controller</em>/login</tt> is always available.
	# Feel free to override this in other controllers to do something different. For example,
	# you might decide you want the site to send you an email logging unauthorised access to
	# a particular controller.
	def login
		logger.warn('!doing a login in the cart?!')
	end


	# Gets a user's preferred currency. Any action called with a +currency+ parameter (e.g.
	# <tt>?currency=USD</tt>) will set a session cookie so that, as long as the templates are set
	# up right, all prices will be displayed in their chosen currency.
	#
	# The first site to use this system was Kiwi Products (http://www.kiwiproducts.co.nz), so
	# that's probably a good place to start looking for tips on how to get on-the-fly currency
	# conversion up and running. It's a pretty sweet feature, and it's got that "something I can
	# play with" factor.
	def get_preferred_currency
		# Gets the full list of currencies for drawing a currency selector with. Probably not
		# strictly needed for <em>every action in the entire site</em>, but at the time I
		# made the decision that it was simpler than putting this code in the template and
		# accessing the database twice.
		@currencies = Currency.find(:all)

		if params[:currency]
			@currency = @currencies.find { |x| x.abbreviation == params[:currency] }
		end

		if session[:currency]
			@currency ||= @currencies.find { |x| x.abbreviation == session[:currency] }
		end

		@currency ||= Currency.default
		@currency ||= Currency.first # in case no default is set...
		session[:currency] = @currency.abbreviation
		@currency
	end


	# parses a date in string form into a Date object. Differs from Date.parse() in that it takes
	# kiwi/english ordering of days/months (eg dd/mm/yyyy, not mm/dd/yyyy). Also if the date is
	# invalid it doesn't throw an error (which clients will see) - it sets the date to a sane nil
	def ffs_parse_date (date_string, default = nil)
		the_string = date_string.chomp.strip

		if the_string =~ /^([0-9]([0-9])?)[-\\\/]([0-9]([0-9])?)[-\\\/](([0-9]{2})([0-9]{2})?)/
			Date.parse(the_string.gsub(/^([0-9]([0-9])?)[-\\\/]([0-9]([0-9])?)[-\\\/](([0-9]{2})([0-9]{2})?)/, '\3/\1/\5'), true)
		else
			Date.parse(the_string, true)
		end
	rescue
		# this is normally just a bad string or invalid date (out of range?). Return default
		default
	end


	# used for parsing dates in a URL. Rails mungs Hashes in URL's (it's a bug, should be fixed
	# in Rails 1.2), so we're de-munging. Dates from this array:
	#
	# params[:date] ---
	#   month - 2
	#   day - 12
	#   year - 2007
	#
	# would appear as so:
	#
	# &date=month2day12year2007
	def parse_broken_rails_date (date_string, default = nil)
		the_string = date_string.chomp.strip

		if the_string =~ /^month([0-9]([0-9])?)day([0-9]([0-9])?)year(([0-9]{2})([0-9]{2})?)/
			Date.parse(the_string.gsub(/^month([0-9]([0-9])?)day([0-9]([0-9])?)year(([0-9]{2})([0-9]{2})?)/, '\5-\1-\3'), true)
		else
			Date.parse(the_string, true)
		end
	rescue
		# this is normally just a bad string or invalid date (out of range?). Return default
		default
	end


	# Generates a random password of the specified length
	def gen_pass (pass_length = 6)
		safe_chars = ["2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "m", "n", "p", "q", "r", "s", "t", "w", "x", "y", "z"]
		new_password = ""

		pass_length.to_i.times do
			new_password += safe_chars[rand(safe_chars.length)]
		end

		new_password
	end


protected
	# Gets the cart for the current session, or makes a new one if there isn't one there already.
	def find_cart
		session[:cart] ||= Cart.new
	end
end
