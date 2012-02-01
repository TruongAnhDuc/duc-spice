# Controller to allow the barcodes spreadsheet to be updated. Checks to see if the currently
# logged-in user is a staff member before allowing access

class Admin::CreditAccountController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Shows some brief statistics on the current uploaded PDF application form, and allows the
	# user to upload a new application form
	#
	# <b>Template:</b> <tt>admin/credit_account/list.rhtml</tt>
	def list
		@current_area = 'credit_account'
		@current_menu = 'credit_account'

		@filename = @configurator[:modules][:credit_account_application_filename][:value]
		the_file = "#{RAILS_ROOT}#{@configurator[:modules][:credit_account_application_path][:value]}#{@filename}"

		unless File.writable? the_file
			flash[:error] = "Credit account application form is not writable - contact Avatar Ltd : #{the_file}"
		else
			if request.post?
				if params[:spreadsheet] and params[:spreadsheet][:spreadsheet]
					# != '' works, but .empty? doesn't - .empty? isn't defined for IOString's :x
					if params[:spreadsheet][:spreadsheet] != ""
						if params[:spreadsheet][:spreadsheet].original_filename
							if !params[:spreadsheet][:spreadsheet].original_filename.empty?
								File.open(the_file, "w") do |buffer|
									buffer << params[:spreadsheet][:spreadsheet].read
								end

								flash[:notice] = "New application form uploaded"
							end
						end
					end
				end
			end
		end

		@application_form_exists = File.file? the_file

		if @application_form_exists
			@file_stats = File.stat the_file
		end
	end
end
