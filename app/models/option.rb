# Represents any sort of user-selectable option for a Product (colour, size, etc).

class Option < ActiveRecord::Base
	has_many :values, :class_name => 'OptionValue', :order => 'position', :dependent => :destroy
#	has_many :product_options, :dependent => :destroy

	# Abstract method describing the option.
	def self.option_type
		'Abstract Option'
	end

	# Creates an option of the given type.
	def self.create_option(params)
		option_class = (Object.subclasses_of(Option).select { |k| k.to_s == params[:type] }).first
		new_object = option_class && option_class.create(params) || nil
	end

	# Converts a CGI-supplied value for use as an option value, taking a reasoned guess at its
	# type. CGI values get messy when AJAX is involved.
	def self.unscramble(value)
		if value.is_a? Array then
			if value.length == 1 && value.first.is_a?(String) && value.first.match(/^[0-9]+(,[0-9]+)*$/)
				value = value.first.split(',').collect { |x| x.to_i }
			end
		elsif value.match(/^\s*-?[0-9]+\s*$/)
			value = value.to_i
		elsif v.match(/^\s*-?[0-9]+\.[0-9]+\s*$/)
			value = value.to_f
		end
		value
	end

	# Returns the label for this option. In most cases it will just be the name, but eventually
	# it might pay to make these two separate, since sometimes you might want to have two
	# different options with the same label.
	def label
		name.match(/\?$/) ? name : name + ":"
	end

	# Describe the currently-selected value (usually by returning the value itself).
	def describe_value(value)
		value
	end

	# Configures this Option with the given parameters.
	def configure_with(params)
		#
		if params[:do] == 'add' and params[:new_value] and !params[:new_value].gsub(/\s/, '').empty?
			values.create({ :value => params[:new_value], :extra_cost => params[:new_extra_cost].to_f, :extra_weight => params[:new_extra_weight].to_f })
		#
		elsif params[:values]
			params[:values] = params[:values].first ? params[:values].first.split(',') : []
			if params[:do] == 'up'
				params[:values].each do |p|
					# *sigh* This should work. Except while rails gives us these nice
					# move_higher and move_lower methods on lists, they ARE NOT scope-
					# -aware. So the 'position' field would move up/down, but only by a
					# value of one - which if an Option's OptionValue's happen to be
					# sparsely spread through the table, means they may not change
					# order at all (within the option_id scope).
					#
					#OptionValue.find(p.to_i).move_higher
					#
					# So, the dumb way:

					last_value = nil
					values.each do |cur_value|
						if last_value && cur_value.id == p.to_i
							cur_value.position, last_value.position = last_value.position, cur_value.position
							cur_value.save
							last_value.save
						end
						last_value = cur_value
					end
				end
			elsif params[:do] == 'down'
				params[:values].reverse.each do |p|
					# Same as above.
					#
					#OptionValue.find(p.to_i).move_lower

					last_value = nil
					values.each do |cur_value|
						if last_value && last_value.id == p.to_i
							cur_value.position, last_value.position = last_value.position, cur_value.position
							cur_value.save
							last_value.save
						end
						last_value = cur_value
					end
				end
			elsif params[:do] == 'delete_value'
				params[:values].each do |p|
					OptionValue.delete(p.to_i)
				end
			end
		end
	end

	# Set the default value for this object. If an array is given, just choose the first element.
	# (multiple-select Option types can override to use the whole array)
	def set_default(value)
		if value.kind_of? Array
			self.default_value = value.first
		else
			self.default_value = value
		end
	end
end

# Generic text field option.
class TextOption < Option
	def self.option_type
		'Text'
	end

	# Set the default value for this object. If an array is given, just choose the first element.
	# This also sets it's only OptionValue to have a value of the default - note that because of
	# the simplified GUI for a TextOption (the OptionValue is effectively hidden), this will also
	# create the OptionValue if it doesn't exist.
	def set_default(value)
		if value.kind_of? Array
			self.default_value = value.first
			if self.values.empty?
				values.create({ :value => value.first })
			else
				# omg - say this 10x fast... :|
				self.values.first.value = value.first
			end
		else
			self.default_value = value
			if self.values.empty?
				values.create({ :value => value })
			else
				self.values.first.value = value
			end
		end
	end
end

# Drop-down list option offering a single choice from several values.
class SingleChoiceOption < Option
	def self.option_type
		'Drop-Down List'
	end

	# Returns the list of available values for this option (optionally, in the context of a given
	# product).
	def available_values(product = nil)
		if !product.nil?
			po = ProductOption.find(:first, :conditions => [ 'product_id = ? AND option_id = ?', product.id, self.id ])
			if po.nil? or po.values.nil?
				values
			else
				po.values.collect { |x| values.find(x) }
			end
		else
			values
		end
	end

	# Returns the label for the currently-selected value.
	def describe_value(value)
		values.find(value.to_i).value
	end
end

# Renders a single-choice option as a list of radio buttons.
class RadioButtons < SingleChoiceOption
	def self.option_type
		'Radio Buttons'
	end
end

# Renders a boolean option as an HTML checkbox.
class CheckBox < SingleChoiceOption
	def self.option_type
		'Single Checkbox'
	end

	# The label is printed beside the checkbox, so we don't need another one.
	def label
		''
	end
end

# Multiple 'buy-now' lines option - inherantly single choice
class MultiLineOption < Option
	def self.option_type
		'Multiple Buy-Line'
	end

	# Returns the list of available values for this option (optionally, in the context of a given
	# product).
	def available_values(product = nil)
		if !product.nil?
			po = ProductOption.find(:first, :conditions => [ 'product_id = ? AND option_id = ?', product.id, self.id ])
			if po.nil? or po.values.nil?
				values
			else
				po.values.collect { |x| values.find(x) }
			end
		else
			values
		end
	end

	# Returns the label for the currently-selected value.
	def describe_value(value)
		values.find(value.to_i).value
	end
end

# Renders a multiple-choice option as an HTML multiple-select box.
class MultiChoiceOption < Option
	def self.option_type
		'Multiple Select Box'
	end

	# Sets the default value or values.
	# Added in ability to just get a single value (not in an array)
	def set_default(value)
		if value.kind_of? Array
			value = value.first ? value.first.split(",") : []
			self.default_value = value.map { |x| x.to_i }.join(",")
		else
			self.default_value = value
		end
	end

	# Describes the list of selected options.
	def describe_value(value)
		(value.nil? or value.empty?) ? '(no options selected)' : value.split(",").collect { |v| values.find(v.to_i).value }.join(', ')
	end
end

# Renders a multiple-choice option as a list of checkboxes.
class MultipleCheckbox < MultiChoiceOption
	def self.option_type
		'Multiple Checkboxes'
	end
end
