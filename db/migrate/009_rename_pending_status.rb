# This migration changes the database schema by renaming the 'pending'
# order-status to 'awaiting_shipping'.
# We also take the opportunity to update the length of the currency symbol.
#
# *** MIGRATING DOWN CAN DAMAGE CURRENCY SYMBOLS as they will be truncated to 8 bytes. ***

class RenamePendingStatus < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# Represents a user's order.
	class Order < ActiveRecord::Base
		belongs_to :user
		has_many :items, :class_name => 'LineItem'
		belongs_to :shipping_zone
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new column
	def self.up
		@actions = ''

		# Change currency symbols to 16 bytes
		change_column :currencies, :symbol, :string, :limit => 16, :null => false, :default => '$'
		@actions += 'Currency symbol field altered to 16 bytes' + "\n"

		# upgrade to varchar(20) to fit 'awaiting_shipping'.
		change_column :orders, :status, :string, :limit => 20, :null => false, :default => 'in_progress'
		@actions += 'Order status field altered to 20 bytes' + "\n"
		Order.update_all('status = \'awaiting_shipping\'', 'status = \'pending\'')

		@actions += '\'pending\' status renamed to \'awaiting_shipping\'' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 8 -> 9 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new column
	def self.down
		@actions = ''

		Order.update_all('status = \'pending\'', 'status = \'awaiting_shipping\'')
		@actions += '\'awaiting_shipping\' status renamed to \'pending\'' + "\n"

		# go back to the old varchar(16) column
		change_column :orders, :status, :string, :limit => 16, :null => false, :default => 'in_progress'
		@actions += 'Order status field altered to 16 bytes' + "\n"

		# and go back to 8-byte currency symbols.  This will cause truncation :(
		change_column :currencies, :symbol, :string, :limit => 8, :null => false, :default => '$'
		@actions += 'Currency symbol field altered to 8 bytes' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Warning: currency symbols longer than 8 bytes will have been truncated!' + "\n"
		puts 'Migration from schema 9 -> 8 complete'
	end
end
