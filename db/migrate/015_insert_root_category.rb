# This migration changes the database schema by automatically inserting the root category
# if it is not already present.  Our initial schema omitted this and it's taken us this long
# to find out!  Existing installations won't be affected, and new installs will be automatically populated.

# Migrating down does nothing as we always need to keep this row (Rocket Cart depends on it).

class InsertRootCategory < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################
	class Category < ActiveRecord::Base
		acts_as_tree :order => 'sequence'

		has_and_belongs_to_many :products, :join_table => 'categories_products', :conditions => 'available = 1'

		def list_scope_condition #:nodoc:
			if parent_id.nil?
				'parent_id IS NULL'
			else
				"parent_id=#{parent_id}"
			end
		end

		# Calculates the correct URL path based on the name of the category and its parents.
		def before_save
			self.name ||= ''
			self.filename ||= self.name.downcase.gsub(/[^a-z0-9]+/, '-')
			if self.parent.nil?
				self.path = ''
			elsif self.parent.path.empty?
				self.path = filename
			else
				self.path = self.parent.path + '/' + self.filename
			end
		end

		# Corrects the paths of any child categories in the event that this category has had its
		# path modified.
		def after_update
			self.children.each do |child|
				child.path = self.path + '/' + child.filename
				child.save
			end
		end

	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	# Insert the row only if it doesn't already exist.
	def self.up
		@actions = ''
		begin
			# This throws an exception when the category is not found, so we can't simply test for nil.
			@root_cat = Category.find(1)
		rescue ActiveRecord::RecordNotFound
			@root_cat = Category.new
			@root_cat.name = ''
			@root_cat.filename = ''
			@root_cat.path = ''
			@root_cat.sequence = 0
			@root_cat.save

			@actions += 'Initial root category created' + "\n"
		end
		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 14 -> 15 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Do nothing, as we always need this row.
	def self.down
		puts 'No actions needed!' + "\n"
	end
end
