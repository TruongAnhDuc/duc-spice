# This migration changes only data - it makes the path fields for Categories include the root
# Category.

class FixCategoryPaths < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	class Category < ActiveRecord::Base
		acts_as_tree :order => 'sequence' # note that sequence starts at 1, NOT 0
	# No longer used
	#	acts_as_nested_set :scope => '1=1'
		has_and_belongs_to_many :products, :join_table => 'categories_products', :conditions => "available = 1 AND (expiry_date IS NULL OR expiry_date >= '#{Date.today.to_s}')"

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

# We're doing this manually in the below migration code
#			if self.parent.nil?
#				self.path = ''
#			elsif self.parent.path.empty?
#				self.path = filename
#			else
#				self.path = self.parent.path + '/' + self.filename
#			end

			if self.sequence.nil? || self.sequence.zero?
				siblings = Category.count(:id, :conditions => list_scope_condition)
				self.sequence = siblings + 1
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

		# Returns the list of ancestors back to the root, for displaying a breadcrumb trail to the
		# current category.
		def breadcrumbs
			self.parent.nil? ? [] : self.parent.breadcrumbs + [self]
		end

		def to_s
			name
		end

		class << self
			# Fetch the list of top-level categories
			def top_level
				r = self.root
				r.nil? ? [] : r.children
			end

			# Get all the categories. Don't use Category.find(:all), because you'll get the dummy root Category as well.
			def all
				self.find(:all, :conditions => 'parent_id IS NOT NULL', :order => 'path ASC')
			end

			# Fetch the dummy root category. This is needed to ensure the NestedSet works properly.
			def root
				self.find(:first, :conditions => 'parent_id IS NULL')
			end
		end
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.recursively_fix (parent_id, parent_path)
		children = Category.find(:all, :conditions => "parent_id = #{parent_id}", :order => "sequence ASC")

		if children
			children.each do |cur_child|
				cur_child.path = parent_path + "/" + cur_child.filename
				cur_child.save

				recursively_fix(cur_child.id, cur_child.path)
			end
		end
	end

	def self.up
		@actions = ''

		root_cat = Category.find(1)
		root_cat.name = "Products"
		root_cat.filename = "products"
		root_cat.path = "products"
		root_cat.save

		self.recursively_fix( 1, "products" )

		@actions += 'Category sequence data fixed' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 22 -> 23 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		root_cat = Category.find(1)
		root_cat.path = "" # this cascades!
		root_cat.save

		children = Category.find(:all, :conditions => "id > 1", :order => "sequence ASC")

		if children
			children.each do |cur_child|
				cur_child.path = cur_child.path.sub( "/", "" )
				cur_child.save
			end
		end

		@actions += 'Category sequence data crapified' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 23 -> 22 complete'
	end
end
