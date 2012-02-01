# Controller to allow the barcodes spreadsheet to be updated. Checks to see if the currently
# logged-in user is a staff member before allowing access

class Admin::BarcodesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_staff
	helper :admin
	layout 'admin'


	# Shows some brief statistics on the current uploaded Excel spreadsheet, and allows the user
	# to upload a new barcodes spreadsheet
	#
	# <b>Template:</b> <tt>admin/barcodes/list.rhtml</tt>
	def list
		@current_area = 'barcodes'
		@current_menu = 'barcodes'

		@filename = @configurator[:modules][:barcodes_spreadsheet_filename][:value]
		the_file = "#{RAILS_ROOT}#{@configurator[:modules][:barcodes_spreadsheet_path][:value]}#{@filename}"

		unless File.writable? the_file
			flash[:error] = "Barcodes spreadsheet is not writable - contact Avatar Ltd : #{the_file}"
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

								flash[:notice] = "New barcodes spreadsheet uploaded"
							end
						end
					end
				end
			end
		end

		@spreadsheet_exists = File.file? the_file

		if @spreadsheet_exists
			@file_stats = File.stat the_file
		end
	end
end
