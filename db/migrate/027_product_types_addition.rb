# This migration changes the database schema by adding a couple of tables for Product Types and
# their assotiated Attributes (Quirks). It also adds a product_type_id field to the main Products
# table.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class ProductTypesAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new tables
	def self.up
		create_table :product_types do |new_table|
			new_table.column :name, :string, :limit => 32, :null => false
		end

		create_table :quirks do |new_table|
			new_table.column :product_type_id, :integer, :null => false, :default => 0
			new_table.column :name, :string, :limit => 32, :null => false
			new_table.column :type, :string, :limit => 16, :null => false
			new_table.column :required, :boolean
			new_table.column :position, :integer, :null => false, :default => 0
		end

		create_table :quirk_values do |new_table|
			new_table.column :product_id, :integer, :null => false, :default => 0
			new_table.column :quirk_id, :integer, :null => false, :default => 0
			new_table.column :value, :text
		end

		add_column :products, :product_type_id, :integer, :null => false, :default => 0

		puts 'Migration from schema 26 -> 27 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns
	def self.down
		drop_table :quirk_values

		drop_table :quirks

		drop_table :product_types

		remove_column :products, :product_type_id

		puts 'Migration from schema 27 -> 26 complete'
	end
end
