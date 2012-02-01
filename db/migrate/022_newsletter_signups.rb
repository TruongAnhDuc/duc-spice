# This migration changes the database schema by adding a 'NewsletterSignups' table to the database,
# which stores email addresses for

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class NewsletterSignups < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new table
	def self.up
		@actions = ''

		create_table :newsletter_signups do |new_table|
			new_table.column :email, :string, :limit => 128
			new_table.column :first_name, :string, :limit => 32
			new_table.column :last_name, :string, :limit => 32
		end
		@actions += 'newsletter signups table added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 22 -> 23 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new table
	def self.down
		@actions = ''

		drop_table :newsletter_signups
		@actions += 'newsletter signups table removed' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 23 -> 22 complete'
	end
end
