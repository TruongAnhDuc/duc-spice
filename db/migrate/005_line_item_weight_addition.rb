# This migration changes the database schema by adding a 'unit_weight' field to the LineItem class.

# Weight and Cost will now be stored in the LineItem table, caching the results of adding up any
# changes due to product option cost/weight modifications (which otherwise require chasing through
# join tables every time).

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class LineItemWeightAddition < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# This migration does not have to convert any old data, so no models need to be used

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new column
	def self.up
		@actions = ''

		add_column :line_items, :unit_weight, :float, :null => false, :default => 0.0
#	this is what we need - but you need Rails 1.1+ (*sigh*)
#		add_column :line_items, :unit_weight, :decimal, :precision => 8, :scale => 3, :null => false, :default => 0.00
#	Rails 1.0 hack - need to edit the db retroactively to be decimal with:
		execute 'ALTER TABLE `line_items` CHANGE `unit_weight` `unit_weight` DECIMAL( 8, 3 ) NOT NULL DEFAULT \'0.00\';'
		@actions += 'unit weight column added' + "\n"

		# now retro-spectively add data for the 'unit_weight' column into old line items
		LineItem.find(:all, :include => [:product]).each do |cur_item|
			# note this is just an approximation - previously product options couldn't alter
			# weight, so this is not factored in
			cur_item.unit_weight = cur_item.product.base_weight
			cur_item.save
		end
		@actions += 'unit weight column filled' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 4 -> 5 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns
	def self.down
		@actions = ''

		remove_column :line_items, :unit_weight
		@actions += 'unit weight column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 5 -> 4 complete'
	end
end
