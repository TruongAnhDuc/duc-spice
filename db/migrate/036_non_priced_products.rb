# This migration changes the database schema by adding a column to the Drafts table for whether or
# not items should have pricing

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class NonPricedProducts < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new columns
	def self.up
		add_column :orders, :priced, :boolean, :null => false, :default => 1
		add_column :drafts, :priced, :boolean, :null => false, :default => 1

		puts 'Migration from schema 35 -> 36 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Removes the new columns
	def self.down
		remove_column :drafts, :priced
		remove_column :orders, :priced

		puts 'Migration from schema 36 -> 35 complete'
	end
end
