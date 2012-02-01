# Represents a shipping zone. Shipping can be based on one or a combination of the following methods:
# * weight
# * number of items
# * flat rate
# The calculation is actually performed by the Cart.
class ShippingZone < ActiveRecord::Base
	has_many :countries, :order => :name, :dependent => :delete_all
	acts_as_list

	def is_default?
		default_zone and !default_zone.zero?
	end

	# Returns a description of the pricing system for this ShippingZone as a human-readable string.
	def describe_price
		a = []
		a << sprintf('$%.2f per item', per_item) unless per_item.zero?
		a << sprintf('$%.2f per kg', per_kg) unless per_kg.zero?
		a << sprintf('$%.2f', flat_rate) unless flat_rate.zero?
		if formula and !formula.empty?
			if formula_description and !formula_description.empty?
				a << formula_description
			else
				a << formula.gsub('I', "'number of items'").gsub('W', "'total weight'").gsub('V', "'total value'")
			end
		end

		a.empty? ? ((name == '[ to be advised ]') ? nil : 'no charge') : a.join(' + ')
	end

	class << self
		# Returns the default shipping zone (or makes one up, assuming free shipping).
		def default_zone
			ShippingZone.find_by_default_zone(1) ||
			ShippingZone.new({
				:id => 0,
				:name => '[ to be advised ]',
				:per_item => 0.0,
				:per_kg => 0.0,
				:flat_rate => 0.0,
				:formula => ''
			})
		end

		# Returns the list of shipping zones for the given country.
		def zones_for(country_name)
			countries = Country.find_all_by_name(country_name)
			if countries.nil? or countries.empty?
				[default_zone]
			else
				countries.collect { |country| country.shipping_zone }.sort { |x, y| -(x.default_zone <=> y.default_zone) || (x.position <=> y.position) }
			end
		end
	end
end
