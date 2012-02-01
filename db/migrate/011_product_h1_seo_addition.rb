# This migration changes the database schema by adding an 'h1' field to the Product class.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class ProductH1SeoAddition < ActiveRecord::Migration

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

		add_column :products, :h1, :string, :limit => 64

		@actions += 'h1 column added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 10 -> 11 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new column
	def self.down
		@actions = ''

		remove_column :products, :h1
		@actions += 'h1 column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 11 -> 10 complete'
	end
end
