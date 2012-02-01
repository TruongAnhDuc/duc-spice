# This migration changes the database schema by adding a `hash_algorithm` field to the `users` table.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY
# It gets worse; users are mostly going to have SHA1 passwords so migrating down will leave them
# unable to log in if they had moved to MD5 passwords
# I don't think there's any way around this.

# This migration assumes that password hashes are currently in SHA1. This is a very dangerous
# assumption! Ideally it should be run before any users are created.

class AddHashAlgorithm < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# No models needed as we are not migrating data (it's impossible to update the hash).

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		@actions = ''

		add_column :users, :hash_algorithm, :integer, :default => 2

		@actions += 'hash_algorithm column added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 17 -> 18 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		remove_column :users, :hash_algorithm

		@actions += 'hash_algorithm column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 18 -> 17 complete'
	end
end
