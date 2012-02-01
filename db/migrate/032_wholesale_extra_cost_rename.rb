# This migration changes the database schema by renaming a column it also copies across retail
# pricing data to the wholesale columns for any existing Products or OptionValues

class WholesaleExtraCostRename < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Rename the field to be consistant
	def self.up
		execute 'ALTER TABLE `option_values` CHANGE COLUMN `wholesale_base_price` `wholesale_extra_cost` decimal(10,2) NOT NULL DEFAULT 0.00'

		Product.find(:all).each do |cur_product|
			cur_product[:wholesale_base_price] = cur_product[:base_price]
			cur_product.save
		end

		OptionValue.find(:all).each do |cur_option_value|
			cur_option_value[:wholesale_extra_cost] = cur_option_value[:extra_cost]
			cur_option_value.save
		end

		puts 'Migration from schema 31 -> 32 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Rename the field to be inconsistant
	def self.down
		execute 'ALTER TABLE `option_values` CHANGE COLUMN `wholesale_extra_cost` `wholesale_base_price` decimal(10,2) NOT NULL DEFAULT 0.00'

		Product.find(:all).each do |cur_product|
			cur_product[:wholesale_base_price] = 0.00
			cur_product.save
		end

		OptionValue.find(:all).each do |cur_option_value|
			cur_option_value[:wholesale_base_price] = 0.00
			cur_option_value.save
		end

		puts 'Migration from schema 32 -> 31 complete'
	end
end
