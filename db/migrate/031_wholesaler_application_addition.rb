# This migration changes the database schema by adding a 'wholesale_application' field to the users
# table

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class WholesalerApplicationAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new field
	def self.up
		add_column :users, :wholesale_application, :string, :limit => 1, :null => false, :default => "-"

		puts 'Migration from schema 30 -> 31 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new field
	def self.down
		remove_column :users, :wholesale_application

		puts 'Migration from schema 31 -> 30 complete'
	end
end
