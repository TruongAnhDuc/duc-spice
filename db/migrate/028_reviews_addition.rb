# This migration changes the database schema by adding a table for Reviews

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class ReviewsAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the reviews table
	def self.up
		create_table :reviews do |new_table|
			new_table.column :product_id, :integer, :null => false, :default => 0
			new_table.column :user_id, :integer, :null => false, :default => 0
			new_table.column :comments, :text
			new_table.column :rating, :integer
			new_table.column :created_at, :datetime
			new_table.column :allowed, :string, :limit => 1, :null => false
		end

		puts 'Migration from schema 27 -> 28 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the reviews table
	def self.down
		drop_table :reviews

		puts 'Migration from schema 28 -> 27 complete'
	end
end
