# This migration changes the database schema by adding an 'Address' table to the database, and by
# giving Order's a delivery as well as a shipping address.

# Address details were stored in the Order table,

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class AddressChangesOnOrders < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# Represents a shipping address for an order. If required, this could be abstracted out and used
	# for a user's billing address as well.
	class ShippingAddress < ActiveRecord::Base
		attr_reader :name, :email, :address, :city, :postcode, :country
		validates_presence_of :name, :address, :city, :country

		def initialize(name, email, address, city, postcode, country)
			@name = name
			@email = email
			@address = address
			@city = city
			@postcode = postcode
			@country = country
		end

		def to_s
			name + "\n" + address + "\n" + city + " " + postcode  + "\n" + country
		end
	end

	# Represents a user's order.
	# Holds a collection of LineItem objects representing the quantity and nature of the products
	# chosen, as well as shipping and status information.
	class Order < ActiveRecord::Base
		belongs_to :user
		has_many :items, :class_name => 'LineItem'
		belongs_to :shipping_zone
	end

	# provides an Address class for Orders (and potentially Users in future).
	class Address < ActiveRecord::Base
		def to_s
			result = @name || ''
			if !@address.empty?
				result = result + ",\n#{@address}"
			end
			if !@city.empty?
				result = result + ",\n#{@city}"
			end
			if !@postcode.empty?
				result = result + " #{@postcode}"
			end
			if !@country.empty?
				result = result + ",\n#{@country}"
			end

			@address
		end

		def empty?
			@name.empty? && @address.empty? && @city.empty? && @postcode.empty? && @country.empty?
		end
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Adds the new columns
	def self.up
		@actions = ''

		create_table :addresses do |new_table|
			new_table.column :name, :string, :limit => 64
			new_table.column :address, :string, :limit => 128
			new_table.column :city, :string, :limit => 128
			new_table.column :postcode, :string, :limit => 32
			new_table.column :country, :string, :limit => 64
		end
		@actions += 'addresses table added' + "\n"

		add_column :orders, :billing_address_id, :integer
		add_column :orders, :delivery_address_id, :integer

		# NOTE
		# these add_index lines are needed for MySQL versions < 4.1.2, which appears to include
		# Digiweb and the Avatar server
		add_index :orders, [:billing_address_id], :name => 'fk_addresses_billing_address'
		add_index :orders, [:delivery_address_id], :name => 'fk_addresses_delivery_address'

		execute 'ALTER TABLE orders ADD CONSTRAINT fk_addresses_billing_address FOREIGN KEY ( billing_address_id ) REFERENCES addresses( id ) '
		execute 'ALTER TABLE orders ADD CONSTRAINT fk_addresses_delivery_address FOREIGN KEY ( delivery_address_id ) REFERENCES addresses( id ) '
		@actions += 'orders table edited' + "\n"

		# now we need to import all the old shipping_address style info into the new addresses
		# table and link to it
		@old_data = Order.find(:all)
		@old_data.each do |cur_old_order|
			# create a new address based on the old data
			new_address = Address.new (
				:name => cur_old_order.shipping_name,
				:address => cur_old_order.shipping_address,
				:city => cur_old_order.shipping_city,
				:postcode => cur_old_order.shipping_postcode,
				:country => cur_old_order.shipping_country)
			new_address.save

			cur_old_order.billing_address_id = new_address.id
			cur_old_order.save
		end
		@actions += 'data migrated' + "\n"

		# now remove the old data columns from the Order table
		remove_column :orders, :shipping_name
		remove_column :orders, :shipping_address
		remove_column :orders, :shipping_city
		remove_column :orders, :shipping_postcode
		remove_column :orders, :shipping_country
		@actions += 'old columns removed' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 3 -> 4 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns
	def self.down
		@actions = ''

		# add the old data columns for address data back into the Order table
		add_column :orders, :shipping_name, :string, :limit => 64
		add_column :orders, :shipping_address, :string, :limit => 128
		add_column :orders, :shipping_city, :string, :limit => 128
		add_column :orders, :shipping_postcode, :string, :limit => 32
		add_column :orders, :shipping_country, :string, :limit => 64

		# load up each Order and populate it with its billing data
		@new_data = Order.find(:all)
		@new_data.each do |cur_new_order|
			# find the billing_address
			new_address = Address.find(cur_new_order[:billing_address_id])

			# put the data back in the Order record
			cur_new_order.shipping_name = new_address.name
			cur_new_order.shipping_address = new_address.address
			cur_new_order.shipping_city = new_address.city
			cur_new_order.shipping_postcode = new_address.postcode
			cur_new_order.shipping_country = new_address.country
			cur_new_order.save

			# delete the billing address record
			cur_new_order.billing_address.destroy

			# delete the delivery address record (if it exists)
			cur_new_order.delivery_address.destroy
		end
		@actions += 'data migrated' + "\n"

		# first remove foreign key constraints
		execute 'ALTER TABLE orders DROP FOREIGN KEY `fk_addresses_billing_address`;'
		execute 'ALTER TABLE orders DROP FOREIGN KEY `fk_addresses_delivery_address`;'
		execute 'ALTER TABLE orders ADD CONSTRAINT fk_addresses_billing_address FOREIGN KEY ( billing_address_id ) REFERENCES addresses( id ) '
		execute 'ALTER TABLE orders ADD CONSTRAINT fk_addresses_delivery_address FOREIGN KEY ( delivery_address_id ) REFERENCES addresses( id ) '
		@actions += 'orders table edited' + "\n"

		remove_column :orders, :billing_address_id
		remove_column :orders, :delivery_address_id
		@actions += 'old columns removed' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 4 -> 3 complete'
	end
end
