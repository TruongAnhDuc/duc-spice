# This migration changes the database schema by adding `short_description` fields to the
# `categories` and `products` tables.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class ShortCategoryProductDescriptions < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# No models needed as we are not migrating data

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		@actions = ''

		add_column :categories, :short_description, :text
		add_column :products, :short_description, :text

		@actions += 'short_description columns added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 23 -> 24 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		remove_column :products, :short_description
		remove_column :categories, :short_description

		@actions += 'short_description columns dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 24 -> 23 complete'
	end
end
