# This migration changes the database schema by adding a 'wholesale' field to the orders table

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class WholesaleOrderAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new field
	def self.up
		add_column :orders, :wholesale, :boolean, :null => false, :default => 0

		puts 'Migration from schema 32 -> 33 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new field
	def self.down
		remove_column :orders, :wholesale

		puts 'Migration from schema 33 -> 32 complete'
	end
end
