# Some definitions for how the older stuff worked (in case anyone ever comes to care):


# ProductOption[:values] appears as so for each ProductOption:

#---
#- X

# X = an OptionValue[:id] for an OptionValue that this ProductOption can have
# There are multiple X lines - one for each OptionValue that the corresponding Option
# has. There is no final endline. Yes, this is a hack for a many-to-many relationship.
# Note that this value is NULL if ALL the OptionValue's for the Option group are
# allowed for this product - it is only filled in if some are not allowed!


class ProductOptionsChangesProducts < ActiveRecord::Migration

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

	# the old ProductOption class (old dropped table)
	class ProductOption < ActiveRecord::Base
		belongs_to :product
		belongs_to :option
		acts_as_list :order => "position", :scope => "product_id"
		serialize :values

		def default_value
			option.default_value
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

		# create the replacement table for product_options (join table between products and
		# option_values)
		create_table :product_option_values, :id => false do |new_table|
			new_table.column :option_value_id, :integer, :null => false, :default => 0
			new_table.column :product_id, :integer, :null => false, :default => 0
			new_table.column :position, :integer, :null => false, :default => 0
			new_table.column :default_value, :boolean
		end
		add_index :product_option_values, [:option_value_id, :product_id], :unique

		# NOTE
		# these add_index lines are needed for MySQL versions < 4.1.2, which appears to include
		# Digiweb and the Avatar server
		add_index :product_option_values, [:option_value_id], :name => 'fk_product_option_value_option_value'
		add_index :product_option_values, [:product_id], :name => 'fk_product_option_value_product'

		execute 'ALTER TABLE `product_option_values` ADD CONSTRAINT `fk_product_option_value_option_value` FOREIGN KEY (`option_value_id`) REFERENCES `option_values` (`id`) ON DELETE CASCADE, ADD CONSTRAINT `fk_product_option_value_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE '

		# convert the data across into the new format
		@old_data = ProductOption.find(:all)
		@old_data.each do |cur_old|
			# NOTE: need to make an Option and test its 'default_value' against this OptionValue.id
			the_option = Option.find(cur_old[:option_id])

			default_value = cur_old[:default_value]

			if cur_old[:values] # some OptionValue's from the Option are not allowed
				# first get an array with the option_values indexes (first line is just '---')
				cur_old[:values].each do |cur_value|
					if the_option[:default_value] == cur_value.id
						default_value ||= the_option[:default_value]
					end
					default_value = default_value.nil? ? true : false

					@new_data = ProductOptionValue.new (
						:product_id => cur_old[:product_id],
						:option_value_id => cur_value,
						:position => cur_old[:position],
						:default_value => default_value)
					@new_data.save
				end
			else # all the Option's OptionValue's are allowed
				option_id = cur_old[:option_id]
				@option_values = OptionValue.find(:all, :conditions => [ "option_id = #{option_id}" ])
				@option_values.each do |cur_option_value|
					if the_option[:default_value] == cur_option_value.id
						default_value ||= the_option[:default_value]
					end
					default_value = default_value.nil? ? true : false

					@new_data = ProductOptionValue.new (
						:product_id => cur_old[:product_id],
						:option_value_id => cur_option_value.id,
						:position => cur_old[:position],
						:default_value => default_value)
					@new_data.save
				end
			end
		end

		# delete the old product-options join table
		drop_table :product_options

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 0 -> 1 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		# create the old table
		execute ' DROP TABLE IF EXISTS `product_options` '

		sql_code = <<_SQL
CREATE TABLE IF NOT EXISTS `product_options` (
	`id` int(11) NOT NULL auto_increment,
	`option_id` int(11) NOT NULL default '0',
	`product_id` int(11) NOT NULL default '0',
	`position` int(11) NOT NULL default '0',
	`default_value` text,
	`values` text,
	PRIMARY KEY  (`id`),
	KEY `option_id` (`option_id`),
	KEY `product_id` (`product_id`)
)
_SQL
		execute sql_code

		# NOTE
		# these 2 lines are needed for MySQL versions < 4.1.2, which appears to include Digiweb
		add_index :product_options, [:option_id], :name => 'fk_product_option_option'
		add_index :product_options, [:product_id], :name => 'fk_product_option_product'

		execute 'ALTER TABLE `product_options` ADD CONSTRAINT `fk_product_option_option` FOREIGN KEY (`option_id`) REFERENCES `options` (`id`) ON DELETE CASCADE, ADD CONSTRAINT `fk_product_option_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE '

		# convert the data across into the old format
		product_ids = ProductOptionValue.find(:all, :group => 'product_id')

		product_ids.each do |cur_product| # the old format has one row for each product
			cur_option_value = OptionValue.find(:first, :conditions => [ "id = #{cur_product[:option_value_id]}" ])

			if OptionValue.count("option_id = #{cur_option_value[:option_id]}") == ProductOptionValue.count("product_id = #{cur_product[:product_id]}")
				values_string = nil
			else
				new_rows = ProductOptionValue.find(:all, :conditions => [ "product_id = #{cur_product[:product_id]}" ])
				values_string = '---'
				new_rows.each do |cur_value|
					values_string += "\n" + '- ' + cur_value[:option_value_id].to_s
				end
			end

			@old_data = ProductOption.new (
				:option_id => cur_option_value[:option_id],
				:product_id => cur_product[:product_id],
				:default_value => nil,
				:values => values_string)
			@old_data[:position] = @old_data.id
			@old_data.save
		end

		# delete the new product-options join table
		drop_table :product_option_values

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 1 -> 0 complete'
	end
end
