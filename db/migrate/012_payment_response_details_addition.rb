# This migration changes the database schema by adding 'response' and 'gateway_used' fields to the
# Order class.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class PaymentResponseDetailsAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

# no models are needed as no data is migrated

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new column
	def self.up
		@actions = ''

		add_column :orders, :gateway_used, :string, :limit => 32
		add_column :orders, :response, :text

		@actions += 'response column added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 11 -> 12 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new column
	def self.down
		@actions = ''

		remove_column :orders, :response
		remove_column :orders, :gateway_used
		@actions += 'response column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 12 -> 11 complete'
	end
end
