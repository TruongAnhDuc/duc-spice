# Controller for all admin-level functions for site-wide settings. Checks to see if the currently
# logged-in user is a client before allowing access

class Admin::SettingsController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_client
	helper :admin
	layout 'admin'


	# Display site-wide configuration options for easy editing.
	# These options are stored in the file <tt>config/rocketcart.yml</tt>, and available globally
	# through the use of the Configurator class.
	#
	# <b>Template:</b> <tt>admin/settings/edit.rhtml</tt>
	def edit
		@current_area = 'settings'
		@current_menu = 'settings'
		@configurator = ConfigReader.new('../config/rocketcart.yml')

		# don't allow the demo admin user to save changes
		# I've allowed for the possibility that the demo section in config.yml might not exist.
		if !@demo_admin
			flash[:errors] = Array.new
			flash[:notice] = Array.new
			if params[:save] and params[:settings]
				params[:settings].each_pair do |group_name, options|
					g = group_name.to_sym
					options.each do |key, value|
						# check this isn't a password confirmation
						unless key =~ /_confirmation$/
							# check this user has permissions to change the configuration option
							if (@current_user.permissions >= @configurator[g][key.to_sym][:level])
								case @configurator[g][key.to_sym][:type]
									when 'boolean'
										value = (value.to_i == 1) ? true : false
									when 'url'
										# use the URI library for URL validation
										begin
											uri = URI.parse(value)
											if uri.class != (URI::HTTP || URI::Generic)
												flash[:errors].push('URL \'' + key + '\' was invalid')
												@bad_value = true
											end
										rescue URI::InvalidURIError
											flash[:errors].push('URL \'' + key + '\' was invalid')
											@bad_value = true
										end
									when 'email'
										# check validity of email? Nah CBF'd...
									when 'int'
										value = value.to_i
									when 'float'
										value = value.to_f
									when 'password'
										unless value == params[:settings][g][key + '_confirmation']
											flash[:errors].push('Values for \'' + key + '\' didn\'t match')
											@bad_value = true
										end
									# text, string, multichoice
									else
										value = value.gsub("\r\n", "\n")
								end

								unless @bad_value
									unless @configurator[g][key.to_sym][:value].to_s == value.to_s
										@configurator[g][key.to_sym][:value] = value

										flash[:notice].push(key)
									end
								end
							end
						end
					end
				end
				@configurator.save
			end
		end
	end


	# Displays all the icon sets available for RocketCart, allowing the user to choose a set
	#
	# <b>Template:</b> <tt>admin/settings/icon_sets.rhtml</tt>
	def icon_sets
		@current_area = 'settings'
		@current_menu = 'settings'

		@icons = {
			'calendar' => true,
			'calculator' => false,
			'cancel' => false,
			'delete' => false,
			'down' => true,
			'down-grey' => true,
			'down2' => true,
			'down2-grey' => true,
			'edit' => true,
			'help' => true,
			'image' => false,
			'left' => true,
			'left-grey' => false,
			'left2' => true,
			'left2-grey' => false,
			'minus' => false,
			'pdf' => true,
			'plus' => false,
			'reload' => true,
			'right' => true,
			'right-grey' => false,
			'right2' => true,
			'right2-grey' => false,
			'save' => false,
			'search' => true,
			'spreadsheet' => false,
			'star' => true,
			'star-grey' => true,
			'up' => true,
			'up-grey' => true,
			'up2' => true,
			'up2-grey' => true,
			'view' => true
		}

		@icon_sets = Hash.new

		folders = Dir.entries(RAILS_ROOT + '/public/images/icons/')
		folders.delete('.')
		folders.delete('..')

		folders.each do |cur_folder|
			@icon_sets[cur_folder] = Hash.new

			# load meta info
			@icon_sets[cur_folder]['_info'] = YAML::load(File.open(RAILS_ROOT + '/public/images/icons/' + cur_folder + '/config.yml'))

			icons = Dir.entries(RAILS_ROOT + '/public/images/icons/' + cur_folder)
			icons.delete('.')
			icons.delete('..')
			icons.delete('config.yml')

			icons.each do |cur_icon|
				icon_bits = cur_icon.split('.')
				icon_name = icon_bits[0]

				unless @icon_sets[cur_folder][icon_name]
					@icon_sets[cur_folder][icon_name] = Hash.new
				end

				@icon_sets[cur_folder][icon_name][icon_bits[1]] = true
			end
		end

		if params[:use] and params[:set_name]
			@design_config[:options][:icons_path] = params[:set_name].to_s
			@design_config.save
			flash[:now] = 'Icons set changed'
		end
	end
end
