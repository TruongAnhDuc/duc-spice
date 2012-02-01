# This migration changes the database schema by adding a couple of fields to the Product class.

# Product's are what will need to be tweaked for SEO. While Product's can take the page title from
# the Product name and Category, there are no SEO fields for the prime <meta> tags.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class PerProductSeoAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new columns
	def self.up
		@actions = ''

		add_column :products, :meta_keywords, :text
		add_column :products, :meta_description, :text
		add_column :products, :image_alt_tag, :text
		add_column :products, :page_title, :text
		@actions += 'meta columns added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 2 -> 3 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns
	def self.down
		@actions = ''

		remove_column :products, :meta_keywords
		remove_column :products, :meta_description
		remove_column :products, :image_alt_tag
		remove_column :products, :page_title
		@actions += 'meta columns dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 3 -> 2 complete'
	end
end
