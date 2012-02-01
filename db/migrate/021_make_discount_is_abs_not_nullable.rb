# This migration changes the database schema by making the `discount_is_abs` field not nullable.

class MakeDiscountIsAbsNotNullable < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# No models needed as we are not migrating data.

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		@actions = ''

		execute 'ALTER TABLE `line_items` MODIFY `discount_is_abs` TINYINT(1) NOT NULL'
		execute 'ALTER TABLE `line_items` ALTER COLUMN `discount_is_abs` SET DEFAULT 0'
		execute 'ALTER TABLE `products` MODIFY `discount_is_abs` TINYINT(1) NOT NULL'
		execute 'ALTER TABLE `products` ALTER COLUMN `discount_is_abs` SET DEFAULT 0'

		@actions += 'discount_is_abs columns made non-nullable' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 21 -> 22 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		execute 'ALTER TABLE `line_items` MODIFY `discount_is_abs` TINYINT(1)'
		execute 'ALTER TABLE `products` MODIFY `discount_is_abs` TINYINT(1)'

		@actions += 'discount_is_abs columns made nullable' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 22 -> 21 complete'
	end
end
