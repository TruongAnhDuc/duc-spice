# Handles the display of static pages (see also the StaticPage documentation).
# By convention, all the static pages look like they're in a directory called "<tt>about</tt>"
# (e.g. "<tt>about/us</tt>"). If you want this to be different, you'll need to fiddle
# with the redirection rules in <tt>.htaccess</tt>.
class StaticPagesController < ApplicationController
	layout 'products'
	before_filter :authorise


	# Display a given static page.
	def index ()
		request_path = request.path.sub(/\/$/, '')

		@static_page = StaticPage.find_by_path(request_path)

		# attempt without filename extensions (removing .html etc)
		if !@static_page && request_path =~ /.*\..*/
			last_dot = request_path.rindex('.')
			no_extension_path = request_path.slice(0, last_dot)
			@static_page = StaticPage.find_by_path(no_extension_path)
		end

		unless @static_page
			@page_not_found = true

			render :text => "Page not found for request '#{request_path}'.", :layout => 'products'
		end
	end


	# Generic contact form (name, email, comments).
	#
	# <b>Todo:</b> Make this more generic, to accept any other fields. Will need to change the
	# underlying Postman function to get this to work.
	def contact_us
		@static_page = StaticPage.find_by_form_name("contact")

		@code_error = false
		if request.post? and params[:send]
			cap = Captcha.new	# I'd use CaptchaRcv as per the php but I need to work out how
						# to make it load the Captcha model file.
			if cap.check(params[:code], params[:code_ref])
				Postman.deliver_contact(@configurator, params[:name], params[:email], params[:comments])

				if params[:newsletter] && params[:newsletter] == 'newsletter'
					signup = NewsletterSignup.new({ :email => params[:email], :first_name => params[:name] })
					signup.save
				end

				render(:action => :thanks) and return
			else
				@code_error = true
				@your_name = params[:name]
				@your_email = params[:email]
				@your_comments = params[:comments]
			end
		else
			@user = @current_user || User.new({:first_name => '', :last_name => ''})
			@your_email = @user.email
			@your_name = @user.to_s.strip
			@your_comments = ''
		end
	end


	# Sends a captcha image.
	def captcha
		cap = Captcha.new
		cap_image = cap.create_image(params[:r])
		send_data(cap_image.png, :type => 'image/png', :disposition => 'inline')
	end


	# Set a new password for the user and email it to them.
	def forgotten_password
		@pw_changed = false
		if request.post? and params[:send]
			# 1. Check that the specified user actually exists
			email = params[:email]
			@user = User.find(:first, :conditions => [ 'email = ?', email ])
			if @user
				# 2. Change the password
				# This code borrowed from the HH migration script
				safe_chars = ['2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'm', 'n', 'p', 'q', 'r', 's', 't', 'w', 'x', 'y', 'z']
				@new_password = ''
				6.times do
					@new_password += safe_chars[rand(safe_chars.length)]
				end
				@user.password = @new_password # Gets hashed automatically in user.save
				@user.password_confirmation = @new_password # otherwise it won't be saved
				@user.save

				# 3. Send the email
				email = Postman.deliver_password(@configurator, @user.email, @user.first_name, @new_password)
				@pw_changed = true
				@user_email = @user.email
			else
				flash.now[:error] = 'Sorry, this email address could not be found in our database.  Please try again.'
			end
		end
	end

	# We allow users to change their own password on the front-end.
	def change_password
		if request.post? and params[:save]
			if @current_user.hashed_password == User.hash_password(params[:current_password], @current_user.hash_algorithm)
				@current_user.password = params[:new_password]
				@current_user.password_confirmation = params[:new_password_confirmation]
				# I know the model checks this, but I'd end up having to handle different errors in different ways.
				if params[:new_password] == params[:new_password_confirmation]
					if @current_user.save
						flash.now[:notice] = 'Your password was updated successfully.'
					else
						flash.now[:error] = 'An error has occurred while updating your password. Please try again.'
					end
				else
					flash.now[:error] = 'Sorry, your password confirmation does not match. Please try again.'
				end
			else
				flash.now[:error] = 'Sorry, your current password was entered incorrectly. Please try again.'
			end
		end
	end
end
