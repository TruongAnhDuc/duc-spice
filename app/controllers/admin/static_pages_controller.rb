# Controller for all admin-level functions for categories. Checks to see if the currently logged-in
# user is a staff member before allowing access

class Admin::StaticPagesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Displays a list of static pages for editing.
	#
	# <b>Template:</b> <tt>admin/static_pages/list.rhtml</tt>
	def list
		@current_area = 'static_pages'
		@current_menu = 'static'

		sort_order ||= get_sort_order("s-name", "name")
		sort_order ||= get_sort_order("s-path", "path")
		sort_order ||= "form_name IS NULL ASC, path ASC"

		page = params[:page] ? params[:page].to_i : 1
		items_per_page = 30
		offset = (page - 1) * items_per_page

		@static_page_count = StaticPage.count()

		@pages = Paginator.new(self, @static_page_count, items_per_page, page)

		if params[:delete] and params[:select]
			if @demo_admin
				redirect_to :action => :static_pages
			else
				c = params[:select].keys.collect { |k| "id=#{k}" }.join(' OR ')
				StaticPage.delete_all c
				redirect_to :action => :list
			end
		else
			@static_pages = StaticPage.find(:all, :order => sort_order, :offset => offset, :limit => items_per_page)
		end
	end


	# Displays a static page for editing. This has a WYSiWYG editor for the main content. Most
	# static pages are user-created, although pages such as the homepage are also handled through
	# this system.
	#
	# <b>Template:</b> <tt>admin/static_pages/edit.rhtml</tt>
	def edit
		@current_area = 'static_pages'
		@current_menu = 'static'

		if params[:id] # edit static page
			@page = StaticPage.find(params[:id])
			# we only allow real admins to edit static pages.
			if params[:save]
				if @demo_admin
					redirect_to(:action => :list) and return false
				else
					params[:page][:path].sub! /\/$/, ''
					if @page.update_attributes params[:page]
						if @page[:form_name]
							routing_path = @page[:path].sub /^\//, ""

							if @page[:form_name] == 'search'
								lines = Array.new
								found = false
								open("#{RAILS_ROOT}/config/routes.rb").each do |cur_line|
									if found
										found = false
										lines << "  map.connect '#{routing_path}', :controller => 'products', :action => 'search'\n"
									else
										lines << cur_line
									end

									if cur_line =~ /^  #-SEARCH/
										found = true
									end
								end
							end

							if @page[:form_name] == 'contact'
								lines = Array.new
								found = false
								open("#{RAILS_ROOT}/config/routes.rb").each do |cur_line|
									if found
										found = false
										lines << "  map.connect '#{routing_path}', :controller => 'static_pages', :action => 'contact_us'\n"
									else
										lines << cur_line
									end

									if cur_line =~ /^  #-CONTACT/
										found = true
									end
								end
							end

							if @page[:form_name] == 'overview'
								lines = Array.new
								found = false
								open("#{RAILS_ROOT}/config/routes.rb").each do |cur_line|
									if found
										found = false
										lines << "  map.connect '#{routing_path}', :controller => 'products', :action => 'products_overview'\n"
									else
										lines << cur_line
									end

									if cur_line =~ /^  #-OVERVIEW/
										found = true
									end
								end
							end

							open("#{RAILS_ROOT}/config/routes.rb", "w") do |router|
								lines.each do |cur_line|
									router.write(cur_line)
								end
							end
						end

						redirect_to(:action => :list) and return true
					end
				end
			end
		end
	end

	# Creates a new static page for editing. This has a WYSiWYG editor for the main content.
	#
	# <b>Template:</b> <tt>admin/static_pages/new.rhtml</tt>
	def new
		@current_area = 'static_pages'
		@current_menu = 'static'

		if params[:save]
			if @demo_admin
				redirect_to(:action => :list) and return false
			else
				if params[:page][:path]
					params[:page][:path].sub! /\/$/, ''
				else
					params[:page][:path] = '/about/' + params[:page][:name].downcase.gsub(/[^a-z0-9]+/, '-')
				end
				@page = StaticPage.new(params[:page])

				if @page.save
					redirect_to(:action => :list) and return true
				end
			end
		else
			@page = StaticPage.new
		end
	end
end
