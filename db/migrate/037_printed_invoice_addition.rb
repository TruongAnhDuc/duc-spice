# This migration changes the database schema by adding a field to the orders table

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class PrintedInvoiceAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new fields
	def self.up
		add_column :orders, :printed_invoice, :boolean, :null => false, :default => 0

		puts 'Migration from schema 36 -> 37 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new fields
	def self.down
		remove_column :orders, :printed_invoice

		puts 'Migration from schema 37 -> 36 complete'
	end
end
