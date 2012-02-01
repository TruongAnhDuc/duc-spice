# This migration changes the database schema by adding an 'active' field to the Users table.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class InactiveUserAccounts < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new field
	def self.up
		add_column :users, :active, :boolean, :null => false, :default => 1

		puts 'Migration from schema 28 -> 29 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new field
	def self.down
		remove_column :users, :active

		puts 'Migration from schema 29 -> 28 complete'
	end
end
