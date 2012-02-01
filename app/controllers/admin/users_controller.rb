# Controller for all admin-level functions for Users. Checks to see if the currently logged-in
# User is a staff member before allowing access

class Admin::UsersController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff, :except => [ :new_admin ]
	before_filter :require_authorisation_client, :only => [ :new_admin ]
	helper :admin
	layout "admin"


	def index
		redirect_to :customers
	end


	# Displays the list of Users that are customers for editing. Also handles functions like
	# deleting customers or adding a new customer.
	#
	# <b>Template:</b> <tt>admin/users/customers.rhtml</tt>
	def customers
		@current_area = "customers"
		@current_menu = "users"

		if params[:select]
			if params[:delete]
				# you MUST manually move child nodes in an acts_as_tree up before calling
				# the destroy! method. Otherwise Rails will automatically go and delete all
				# the child nodes even before the selected nodes' 'before_destroy' callback
				# is triggered!
				params[:select].keys.each do |k|
					the_customer = User.find(k)
					if the_customer
						User.destroy(the_customer[:id])
					end
				end
				redirect_to :action => :customers
			end
		end

		sort_order ||= get_sort_order("s-name", [ "first_name", "last_name" ])
		sort_order ||= get_sort_order("s-email", "email")
		sort_order ||= get_sort_order("s-application", "wholesale_application")
		sort_order ||= "first_name ASC, last_name ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		where_parts = Array.new
		if params[:query] and !params[:query].empty?
			@keywords = params[:query].split
			@query = @keywords.join(" ")
			mode = params[:mode] || "all"
			where_parts = @keywords.collect { |k| "(first_name LIKE '%#{k}%' OR last_name LIKE '%#{k}%' OR email LIKE '%#{k}%')" }
		end
		if params[:applicants_only] and !params[:applicants_only].empty?
			where_parts << "(wholesale_application='p')"
			@applicants_only = true
		else
			@applicants_only = false
		end

		if where_parts.empty?
			where_clause = "1=1"
		else
			where_clause = where_parts.join(mode == "all" ? " AND " : " OR ")
		end

		@customer_count = User.count("user_level=0 AND #{where_clause}")

		@pages = Paginator.new(self, @customer_count, items_per_page, page)

		@customers = User.find(:all, :conditions => "user_level=0 AND #{where_clause}", :order => sort_order, :offset => offset, :limit => items_per_page)
	end


	# Creates a new customer.
	#
	# <b>Templates:</b> <tt>admin/users/new_customer.rhtml</tt>
	def new_customer
		@current_area = "customers"
		@current_menu = "users"

		if request.post? && params[:customer]
			@customer = User.new(params[:customer])

			if params[:customer][:password].empty? && params[:customer][:password_confirmation].empty?
				# generate a password
				generated_password = gen_pass()
				@customer.password = generated_password
				@customer.password_confirmation = generated_password
			end

			if @customer.save
				flash[:notice] = "Customer successfully created"
				if generated_password
					flash[:notice] += " with password: #{generated_password}"
				end
				redirect_to :action => :customers
			else
				@customer.password = nil
				@customer.password_confirmation = nil
			end
		else
			@customer = User.new
		end
	end


	# Displays User details for editing.
	#
	# <b>Template:</b> <tt>admin/users/edit_customer.rhtml</tt>
	def edit_customer
		@current_area = "customers"
		@current_menu = "users"

		@customer = User.find(params[:id])

		if @customer && @customer.permissions == :user
			if request.post?
				if params[:save] && !params[:save].empty?
					@customer[:first_name] = params[:customer][:first_name]
					@customer[:last_name] = params[:customer][:last_name]
					@customer[:email] = params[:customer][:email]
					@customer[:active] = (params[:customer][:active].to_i == 1)
					@customer[:sees_wholesale] = (params[:customer][:sees_wholesale].to_i == 1)
				end

				if params[:approve] && !params[:approve].empty?
					# Application successful, send the appropriate emails
					generated_password = gen_pass()
					@customer.password = generated_password
					@customer.password_confirmation = generated_password

					@customer[:sees_wholesale] = true
					@customer[:wholesale_application] = "y"

					Postman.deliver_wholesale_approved(@configurator, @customer)
				elsif params[:deny] && !params[:deny].empty?
					@customer[:sees_wholesale] = false
					@customer[:wholesale_application] = "n"
				end

				if params[:password] && !params[:password].empty?
					if params[:customer][:password].empty? && params[:customer][:password_confirmation].empty?
						# generate a password
						generated_password = gen_pass()
						@customer.password = generated_password
						@customer.password_confirmation = generated_password
					else
						@customer.password = params[:customer][:password]
						@customer.password_confirmation = params[:customer][:password_confirmation]
					end
				end

				if @customer.save
					flash[:notice] = "Changes successfully saved"
					if generated_password
						flash[:notice] += "; password set to: #{generated_password}"
					end
					redirect_to :action => :customers
				end
			end
		else
			flash[:notice] = "Bad Customer ID #"
			redirect_to :action => :customers
		end
	end

	# Displays the list of Users that are admins for editing. Also handles functions like
	# deleting admins or adding a new admins. Admins will be able to delete/edit/create other
	# admin accounts below their own level (but not above or equal). They will be able to see
	# other admin accounts AT their own level (but not above).
	#
	# <b>Template:</b> <tt>admin/users/admins.rhtml</tt>
	def admins
		@current_area = "admins"
		@current_menu = "users"

		if params[:select]
			if params[:delete]
				# you MUST manually move child nodes in an acts_as_tree up before calling
				# the destroy! method. Otherwise Rails will automatically go and delete all
				# the child nodes even before the selected nodes' 'before_destroy' callback
				# is triggered!
				params[:select].keys.each do |k|
					the_admin = User.find(k)
					if the_admin && the_admin.permissions < @current_user.permissions
						User.destroy(the_admin[:id])
					end
				end
				redirect_to :action => :admins
			end
		end

		sort_order ||= get_sort_order("s-name", [ "first_name", "last_name" ])
		sort_order ||= get_sort_order("s-level", "user_level")
		sort_order ||= get_sort_order("s-active", "active")
		sort_order ||= "first_name ASC, last_name ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		if params[:query] and !params[:query].empty?
			@keywords = params[:query].split
			@query = @keywords.join(" ")
			mode = params[:mode] || "all"
			where_parts = @keywords.collect { |k| "(first_name LIKE '%#{k}%' OR last_name LIKE '%#{k}%' OR email LIKE '%#{k}%')" }
			where_clause = where_parts.join(mode == "all" ? " AND " : " OR ")
		else
			where_clause = "1=1"
		end

		@admin_count = User.count("user_level<=#{@current_user.permissions.to_i} AND user_level>0 AND #{where_clause}")

		@pages = Paginator.new(self, @admin_count, items_per_page, page)

		@admins = User.find(:all, :conditions => "user_level<=#{@current_user.permissions.to_i} AND user_level>0 AND #{where_clause}", :order => sort_order, :offset => offset, :limit => items_per_page)
	end


	# Creates a new admin.
	#
	# <b>Templates:</b> <tt>admin/users/new_admin.rhtml</tt>
	def new_admin
		@current_area = "admins"
		@current_menu = "users"

		# create a hash with the user levels you can create (
		@user_levels = Hash.new
		for k in 1..(@current_user.permissions.to_i - 1) do
			perm = UserPermissions.new(k)

			@user_levels[perm.to_i] = perm.to_s
		end

		if request.post? && params[:admin]
			@admin = User.new(params[:admin])

			if @admin.permissions < @current_user.permissions
				if params[:admin][:password].empty? && params[:admin][:password_confirmation].empty?
					# generate a password
					generated_password = gen_pass()
					@admin.password = generated_password
					@admin.password_confirmation = generated_password
				end

				if @admin.save
					flash[:notice] = "admin successfully created"
					if generated_password
						flash[:notice] += " with password: #{generated_password}"
					end
					redirect_to :action => :admins
				else
					@admin.password = nil
					@admin.password_confirmation = nil
				end
			else
				flash[:notice] = "Bad Admin level"
				redirect_to :action => :admins
			end
		else
			@admin = User.new
		end
	end


	# Displays User details for editing.
	#
	# <b>Template:</b> <tt>admin/users/edit_admin.rhtml</tt>
	def edit_admin
		@current_area = "admins"
		@current_menu = "users"

		@admin = User.find(params[:id])

		if @admin && @admin.permissions > :user && ((@admin.permissions < @current_user.permissions) || (@admin[:id] == @current_user[:id]))
			if request.post?
				if params[:save] && !params[:save].empty?
					@admin[:first_name] = params[:admin][:first_name]
					@admin[:last_name] = params[:admin][:last_name]
					@admin[:email] = params[:admin][:email]
					@admin[:active] = (params[:admin][:active].to_i == 1)
				end

				if params[:password] && !params[:password].empty?
					if params[:admin][:password].empty? && params[:admin][:password_confirmation].empty?
						# generate a password
						generated_password = gen_pass()
						@admin.password = generated_password
						@admin.password_confirmation = generated_password
					else
						@admin.password = params[:admin][:password]
						@admin.password_confirmation = params[:admin][:password_confirmation]
					end
				end

				if @admin.save
					flash[:notice] = "Changes successfully saved"
					if generated_password
						flash[:notice] += "; password set to: #{generated_password}"
					end
					redirect_to :action => :admins
				end
			end
		else
			flash[:notice] = "Bad Admin ID #"
			redirect_to :action => :admins
		end
	end
end
