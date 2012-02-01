# Controller for all admin-level functions for payment gateways. Checks to see if the currently
# logged-in user is a client before allowing access

class Admin::PaymentGatewaysController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_client
	helper :admin
	layout 'admin'


	# Displays a list of available PaymentModule options. Note that these must exist
	# in the database with the correct path to the module script (usually a PHP file) and
	# <tt>config.yml</tt> file: if in doubt, copy the database records from the
	# main Rocket Cart database.
	#
	# <b>Template:</b> <tt>admin/payment_gateways/list.rhtml</tt>
	def list
		@current_area = 'gateways'
		@current_menu = 'settings'

		# demo admins cannot edit payment gateway config
		# UPDATE: the menu item has been deleted but I've left this condition here
		# as the page is still accessible by manually entering the URL.
		if params[:save] and params[:module] and !@demo_admin
			if params[:module].to_i.zero?
				PaymentModule.update_all 'active=0'
			else
				PaymentModule.update_all 'active=0', "id <> #{params[:module]}"
				PaymentModule.update params[:module], { :active => 1 }

				@payment_gateway = PaymentModule.default
				if params[:config] and !@payment_gateway.config.nil?
					config = {}
					params[:config].each_pair do |group, options|
						config[group.to_sym] = options.symbolize_keys
					end
					@payment_gateway.configure(config)
				end
			end
		end
		# demo admins cannot see the configured values so they can't see our keys
		if @demo_admin
			@payment_gateway = PaymentModule.none
			@payment_gateways = nil
			@config = nil
		else
			@payment_gateway = PaymentModule.default
			@config = YAML::load(IO.read(@payment_gateway.config)) unless @payment_gateway.config.nil? or !File.exist?(@payment_gateway.config)
			@payment_gateways = PaymentModule.find(:all, :order => 'name ASC')
		end
	end


	# Displays a payment gateway for editing, and updates the options by writing them in YAML
	# format to the PaymentGateway's config file. Called via AJAX from the Payment Gateways page.
	#
	# <b>Template:</b> <tt>admin/payment_gateways/_payment_gateway.rhtml</tt>
	def edit
		@current_area = 'gateways'
		# demo admins cannot see the configured values so they can't see our keys
		if params[:id].to_i.zero? or @demo_admin
			@payment_gateway = PaymentModule.none
			@config = nil
		else
			@payment_gateway = Plugin.find(params[:id])
			@config = YAML::load(IO.read(@payment_gateway.config)) unless @payment_gateway.config.nil? or !File.exist?(@payment_gateway.config)
		end
		render :partial => 'payment_gateway'
	end
end
