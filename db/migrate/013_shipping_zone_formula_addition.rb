# This migration changes the database schema by adding 'formula' and 'formula_description' fields
# to the ShippingZone class

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class ShippingZoneFormulaAddition < ActiveRecord::Migration

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

		add_column :shipping_zones, :formula, :string, :limit => 255
		add_column :shipping_zones, :formula_description, :string, :limit => 255

		@actions += 'formula columns added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 12 -> 13 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new column
	def self.down
		@actions = ''

		remove_column :shipping_zones, :formula
		remove_column :shipping_zones, :formula_description
		@actions += 'formula columns dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 13 -> 12 complete'
	end
end
