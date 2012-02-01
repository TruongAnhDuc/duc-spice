# This migration changes only data - it adds the two default payment gateways (if applicable for
# the version of Rocket Cart). Existing installations won't be affected, and new installs will be
# automatically populated.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY
# Migrating down will remove all payment gateways

class InsertPaymentGateways < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# No models needed as we are not migrating data (it's impossible to update the hash).

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		@actions = ''

		# we have to use SQL as the plugins table has no models etc
		execute "INSERT INTO plugins (type,name,description,script,config,active) VALUES ('PaymentModule', 'RocketSecure', 'Users will be taken to a secure page to enter their credit card details. These details will then be made available to the specified staff member via a password-protected interface.', '/payments/rocket-secure/index.php', 'payments/rocket-secure/config.yml', 1)"

#SNIP=dps
# DO NOT REMOVE THE ABOVE COMMENT. It is used to remove the above feature

		# Rocket Cart Pro installations need this payment gateway
		execute "INSERT INTO plugins (type,name,description,script,config,active) VALUES ('PaymentModule', 'Payment Express', 'Processes credit-card transactions in real-time using Payment Express''s Hosted Payments Page.', '/payments/payment-express/index.php', 'payments/payment-express/config.yml', 1)"

# DO NOT REMOVE THE BELOW COMMENT. It is used to remove the above feature
#/SNIP=dps

		@actions += 'Payment gateways inserted' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 19 -> 20 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		execute "DELETE FROM plugins WHERE type='PaymentModule'"

		@actions += 'Payment gateways removed' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 20 -> 19 complete'
	end
end
