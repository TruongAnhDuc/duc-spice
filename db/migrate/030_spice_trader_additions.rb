# This migration changes the database schema by adding fields to the users, products,
# option_values, line_items and orders tables

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class SpiceTraderAdditions < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new fields
	def self.up
		add_column :users, :sees_wholesale, :boolean, :null => false, :default => 0

		add_column :products, :wholesale_only, :boolean, :null => false, :default => 0
		add_column :products, :wholesale_base_price, :float, :null => false, :default => 0.00
		execute 'ALTER TABLE `products` CHANGE `wholesale_base_price` `wholesale_base_price` DECIMAL( 8, 3 ) NOT NULL DEFAULT \'0.00\';'

		add_column :option_values, :wholesale_only, :boolean, :null => false, :default => 0
		add_column :option_values, :wholesale_base_price, :float, :null => false, :default => 0.00
		execute 'ALTER TABLE `option_values` CHANGE `wholesale_base_price` `wholesale_base_price` DECIMAL( 8, 3 ) NOT NULL DEFAULT \'0.00\';'

		add_column :line_items, :wholesale, :boolean, :null => false, :default => 0

		add_column :orders, :is_draft, :boolean, :null => false, :default => 0

		puts 'Migration from schema 29 -> 30 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new fields
	def self.down
		remove_column :orders, :is_draft

		remove_column :line_items, :wholesale

		remove_column :option_values, :wholesale_base_price
		remove_column :option_values, :wholesale_only

		remove_column :products, :wholesale_base_price
		remove_column :products, :wholesale_only

		remove_column :users, :sees_wholesale

		puts 'Migration from schema 30 -> 29 complete'
	end
end
