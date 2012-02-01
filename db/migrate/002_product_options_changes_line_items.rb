# Some definitions for how the older stuff worked (in case anyone ever comes to care):


# LineItem[:options] appears as so for each LineItem:

#---
#X: "Y"
#A: B

# A = the Option[:id] for the appropriate Option group
# B = the OptionValue[:id] for the chosen OptionValue from the above Option group
# X = the ProductOption[:id] for the appropriate Option and Product
# Y = the Option[:default_value] for the appropriate Option group (why the heck is this
#     here?)
# Note that the order of the X and A lines is psuedo-random. There is no final endline.
# There conceptially should be able to be multiple X or A lines. There would be one of
# each for every chosen option on the Product that this LineItem represents. I have no
# idea why all this data is here - the A line is a hack for a many-to-many relationship
# - but the X line is mysterious. It's included in the conversion routines in case it
# somehow matters. Yes, the Y is always quoted (was cast to a string before getting put
# in here?).
# This is a serialized Ruby Hash. It assumes a single 'Option' for each LineItem, and
# has 2 Hash values inside.


class ProductOptionsChangesLineItems < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# these classes should be included here to stop this migration file becoming unusable
	# in the future if they recieve significant changes in structure.

	# the new ProductOptionValue class (newly created table)
	class ProductOptionValue < ActiveRecord::Base
		belongs_to :product
		belongs_to :option_value
		acts_as_list :order => "position", :scope => "product_id"

		# to ensure we can only have 1 of each concrete option for each product
		validates_uniqueness_of :option_value_id, :scope => :product_id

		def default_value
			option.default_value
		end
	end

	# the old OptionValue class (unmodified - for claiming OptionValue id's within Option id groups)
	class OptionValue < ActiveRecord::Base
		belongs_to :option
		acts_as_list :order => "position", :scope => "option_id"
	end

	# the new LineItemOptionValue class (newly created table)
	class LineItemOptionValue < ActiveRecord::Base
		belongs_to :line_item
		belongs_to :option_value

		# to ensure we can only have 1 of each concrete option for each line_item
		validates_uniqueness_of :option_value_id, :scope => :line_item_id
	end

	# the old LineItem class (modified)
	class LineItem < ActiveRecord::Base
		belongs_to :product
		belongs_to :order
		serialize :options

		# Creates a LineItem for a given product.
		def self.for_product(product, quantity = 1, options = {})
			item = self.new
			item.quantity = quantity
			item.product = product
			item.unit_price = product.price
			product.product_options.each do |option|
				options[option.id] ||= option.default_value
			end
			item.options = options
			item
		end

		# Sets a product option.
		def set_option(key, value)
			if value.is_a? Array
				value = value.join ","
			end
			self.options[key] = value
		end

		# Returns +true+ if this LineItem is the same as another one.
		def same_as?(l2)
			self.product.id == l2.product.id && self.options == l2.options
		end
	end

	# the Option class (used for conversion - not changed)
	class Option < ActiveRecord::Base
		has_many :values, :class_name => "OptionValue", :order => "position", :dependent => :destroy
		has_many :product_options, :dependent => :destroy

		# Abstract method describing the option.
		def self.option_type
			"Abstract Option"
		end

		# Creates an option of the given type.
		def self.create_option(params)
			option_class = (Object.subclasses_of(Option).select { |k| k.to_s == params[:type] }).first
			new_object = option_class && option_class.create(params) || nil
		end

		# Converts a CGI-supplied value for use as an option value, taking a reasoned guess at its type.
		# CGI values get messy when AJAX is involved.
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

		# Renders a preview of the Option.
		def preview
			render("option_#{self.id}_preview")
		end

		# Renders the option in the context of a given value and/or product (which may or may not have a value chosen for it).
		def render(field_id, value = nil, product = nil)
			value ||= self.default_value || ""
			"<input class=\"text\" type=\"text\" name=\"#{field_id}\" value=\"#{value}\" />"
		end

		# Returns the label for this option. In most cases it will just be the name, but eventually it might pay to make these two
		# separate, since sometimes you might want to have two different options with the same label.
		def label
			name.match(/\?$/) ? name : name + ":"
		end

		# Describe the currently-selected value (usually by returning the value itself).
		def describe_value(value)
			value
		end

		# Render a configuration UI for this option.
		def config
			"<p>No additional configuration is available</p>"
		end

		# Configure this option with the given parameters.
		def configure_with(params)

		end

		# Set the default value for this object.
		def set_default(value)
			self.default_value = value
		end
	end

	# needed for inheritance with the above Option class
	class SingleChoiceOption < Option
		def self.option_type
			"Drop-Down List"
		end

		# Returns the list of available values for this option (optionally, in the context of a given product).
		def available_values(product = nil)
			if !product.nil?
				po = ProductOption.find(:first, :conditions => [ "product_id = ? AND option_id = ?", product.id, self.id ])
				if po.nil? or po.values.nil?
					values
				else
					po.values.collect { |x| values.find(x) }
				end
			else
				values
			end
		end

		# Renders this option to an HTML +select+ tag.
		def render(field_id, value = nil, product = nil)
			selected_value = !value.nil? ? value : self.default_value || nil
			r = "<select name=\"#{field_id}\">"
			available_values(product).each do |v|
				r += "<option value=\"#{v.id}\""
				if v.id.to_s == selected_value.to_s then
					r += " selected=\"selected\""
				end
				r += ">#{v.value}</option>"
			end
			r += "</select>"
		end

		# Render a configuration UI for this option.
		def config
			r = "<table class=\"option-gui\"><tr><td>"
			r += "<select name=\"values[]\" multiple=\"multiple\" size=\"7\">"
			r += values.collect { |v| "<option value=\"#{v.id}\">#{v.value}</option>" }.join
			r += "</select><br />"
			r += "</td><td>"
			r += "<input class=\"button\" type=\"submit\" name=\"up\" value=\"Move Up\" onclick=\"$('do-#{id}').value='up'\" /><br />"
			r += "<input class=\"button\" type=\"submit\" name=\"down\" value=\"Move Down\" onclick=\"$('do-#{id}').value='down'\" /><br />"
			r += "<input class=\"button\" type=\"submit\" name=\"delete\" value=\"Delete\" onclick=\"$('do-#{id}').value='delete_value'\" />"
			r += "</td></tr><tr><td colspan=\"2\">"
			r += "<input class=\"text\" type=\"text\" name=\"new_value\" />"
			r += "<input class=\"button\" type=\"submit\" name=\"add\" value=\"Add\" onclick=\"$('do-#{id}').value='add'\" />"
			r += "</td></tr></table>"
		end

		# Configures this option with the given parameters.
		def configure_with(params)
			if params[:do] == "add"
				values.create({ :value => params[:new_value] })
			elsif params[:values]
				params[:values] = params[:values].first ? params[:values].first.split(",") : []
				if params[:do] == "up"
					params[:values].each do |p|
						OptionValue.find(p.to_i).move_higher
					end
				elsif params[:do] == "down"
					params[:values].reverse.each do |p|
						OptionValue.find(p.to_i).move_lower
					end
				elsif params[:do] == "delete_value"
					params[:values].each do |p|
						OptionValue.delete(p.to_i)
					end
				end
			end
		end

		# Returns the label for the currently-selected value.
		def describe_value(value)
			values.find(value.to_i).value
		end
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		@actions = ''

		# create the join table between option_values and line_items
		create_table :line_item_option_values, :id => false do |new_table|
			new_table.column :line_item_id, :integer, :null => false, :default => 0
			new_table.column :option_value_id, :integer, :null => false, :default => 0
		end
		add_index :line_item_option_values, [:line_item_id, :option_value_id], :unique

		add_index :line_item_option_values, [:option_value_id], :name => 'fk_line_item_option_value_option_value'
		add_index :line_item_option_values, [:line_item_id], :name => 'fk_line_item_option_value_line_item'

		execute 'ALTER TABLE `line_item_option_values` ADD CONSTRAINT `fk_line_item_option_value_option_value` FOREIGN KEY (`option_value_id`) REFERENCES `option_values` (`id`) ON DELETE CASCADE, ADD CONSTRAINT `fk_line_item_option_value_line_item` FOREIGN KEY (`line_item_id`) REFERENCES `line_items` (`id`) ON DELETE CASCADE '

		old_line_items = LineItem.find(:all)
		old_line_items.each do |cur_line_item|
			if cur_line_item[:options]
				cur_line_item[:options].each do |cur_line|
					if cur_line != '---'
						if !cur_line[1].kind_of?(String)
							@new_row = LineItemOptionValue.new (
								:line_item_id => cur_line_item[:id],
								:option_value_id => cur_line[1]
							)
							@new_row.save
						end
					end
				end
			end
		end

		# alter the old lineitems table
		remove_column :line_items, :options

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 1 -> 2 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		# alter the new lineitems table
		add_column :line_items, :options, :text

		# in order to re-create the old table we will need to find() the Option, the OptionValue,
		# and the ProductOption assotiated with the LineItem. We get the OptionValue through the
		# new (now defunct) join table. We get the Option through the OptionValue. We get the
		# ProductOption through the Product (find() on Product, then on ProductOption :( ). So yes,
		# this conversion will be slow.
		line_items = LineItem.find(:all)
		line_items.each do |cur_line_item|
			# NOTE the :first - the old format does NOT support > 1 option applied
			# to a single LineItem

			joins = LineItemOptionValue.find(:all, :conditions => [ "line_item_id = #{cur_line_item.id}" ])

			serial_hash = nil

			joins.each do |cur_line_item_option_value|
				option_value = OptionValue.find(cur_line_item_option_value[:option_value_id])

				option = Option.find(option_value[:option_id])

				# the 0 is a hard-coded hack. I know this :P. But that hash line
				# doesn't seem to be used anywhere, and the ID value that goes
				# there is for a table that only exists in DB-Schema 0 (hmm,
				# perhaps migrations 1 and 2 should have been merged after all).
				serial_hash = {
					option[:id] => cur_line_item_option_value[:option_value_id],
					0 => option[:default_value].to_s
				}
			end

			if serial_hash
				cur_line_item[:options] = serial_hash
			end
			cur_line_item.save
		end

		# delete the new lineitem-options join table
		drop_table :line_item_option_values

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 2 -> 1 complete'
	end
end
