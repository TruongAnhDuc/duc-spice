# provides an Address class for Orders (and potentially Users in future).

class Address < ActiveRecord::Base
	has_many :orders
	validates_length_of :name, :minimum => 1, :message => 'Please enter a name.'
	validates_length_of :address, :minimum => 1, :message => 'Please enter an address.'
	validates_length_of :city, :minimum => 1, :message => 'Please enter a city.'
# Not likely to be a required field in general - needs a config option?
#	validates_length_of :phone_no, :minimum => 1, :message => 'Please enter a phone number.'

	def to_s
		result = name || ''
		if address and !address.empty?
			result = result + ",\n#{address}"
		end
		if city and !city.empty?
			result = result + ",\n#{city}"
		end
		if postcode and !postcode.empty?
			result = result + " #{postcode}"
		end
		if country and !country.empty?
			result = result + ",\n#{country}"
		end

		result
	end

	def empty?
		name.empty? && address.empty? && city.empty? && postcode.empty? && country.empty?
	end
end
