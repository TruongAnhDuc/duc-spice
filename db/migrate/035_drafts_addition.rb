# This migration changes the database schema by adding a table for Drafts and another for
# DraftProducts

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class DraftsAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the reviews table
	def self.up
		create_table :drafts do |new_table|
			new_table.column :user_id, :integer, :null => false, :default => 0
			new_table.column :created_at, :datetime
		end

		create_table :draft_items do |new_table|
			new_table.column :draft_id, :integer, :null => false, :default => 0
			new_table.column :product_id, :integer, :null => false, :default => 0
			new_table.column :option_value_id, :integer, :null => false, :default => 0
			new_table.column :quantity, :integer, :null => false, :default => 0
		end

		puts 'Migration from schema 34 -> 35 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the reviews table
	def self.down
		drop_table :draft_items
		drop_table :drafts

		puts 'Migration from schema 35 -> 34 complete'
	end
end
