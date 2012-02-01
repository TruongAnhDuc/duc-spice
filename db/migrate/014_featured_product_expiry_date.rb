# This migration changes the database schema by adding a 'featured_expires' field
# to the Product class, so featured products can have an automatic expiry date.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class FeaturedProductExpiryDate < ActiveRecord::Migration

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

		add_column :products, :featured_until, :datetime

		@actions += 'featured_until column added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 13 -> 14 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new column
	def self.down
		@actions = ''

		remove_column :products, :featured_until
		@actions += 'featured_until column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 14 -> 13 complete'
	end
end
