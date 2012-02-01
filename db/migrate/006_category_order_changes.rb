# This migration changes the database schema by adding a 'sequence' field to the Category class,
# and removing the 'lft' and 'rgt' fields.

# Previously Categories were stored as both a tree and a nested set. The nested set capabilities
# (selection/modification of subtrees, all leaf/tree nodes with a single query) aren't needed for
# our categories, so the nested set capabilities are wasted.

# Categories will now be stored as a tree only. Ordering of sibling nodes in the tree will be done
# through an explicit 'sequence' field (ordering is not accessible in the admin interfaces yet -
# but is kept as a likely extension).

# NOTE THAT MIGRATING THROUGH THIS STEP WILL DUMP DATA PERMANENTLY (ordering data for Categories)

class CategoryOrderChanges < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# Old Category class
	class Category < ActiveRecord::Base
		acts_as_tree :order => 'lft'
		acts_as_nested_set :scope => '1=1'
		# CRRRAAAAZZZY! It's a tree, AND a nested set...
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

		# Display name for the category in a select box (admin area use only).
		def option_label
			name + ' (' + path + ')'
		end

		# Returns the list of ancestors back to the root, for displaying a breadcrumb trail to the
		# current category.
		def breadcrumbs
			self.parent.nil? ? [] : self.parent.breadcrumbs + [self]
		end

		def first? #:nodoc:
			lft == parent.lft + 1
		end

		def last? #:nodoc:
			rgt == parent.rgt - 1
		end

		def higher_item #:nodoc:
			Category.find(:first, :conditions => [ 'rgt = ?', lft - 1])
		end

		def lower_item #:nodoc:
			Category.find(:first, :conditions => [ 'lft = ?', rgt + 1])
		end

		def move_higher #:nodoc:
			if !first?
				h = higher_item
				d = lft - h.lft
				w = rgt - lft + 1
				Category.transaction do
					Category.update_all("lft = -(lft + #{w}), rgt = rgt + #{w}", "lft >= #{h.lft} AND lft < #{h.rgt}")
					Category.update_all("lft = lft - #{d}, rgt = rgt - #{d}", "lft >= #{lft} AND lft < #{rgt}")
					Category.update_all('lft = -lft', 'lft < 0')
				end
			end
		end

		def move_lower #:nodoc:
			if !last?
				l = lower_item
				d = l.lft - lft
				w = l.rgt - l.lft + 1
				Category.transaction do
					Category.update_all("lft = -(lft - #{d}), rgt = rgt - #{d}", "lft >= #{l.lft} AND lft < #{l.rgt}")
					Category.update_all("lft = lft + #{w}, rgt = rgt + #{w}", "lft >= #{lft} AND lft < #{rgt}")
					Category.update_all('lft = -lft', 'lft < 0')
				end
			end
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

	# Adds the new sequence column, removes the old nested set columns
	def self.up
		@actions = ''

		add_column :categories, :sequence, :integer, :null => false, :default => 0
		@actions += 'sequence column added' + "\n"

		# now add initial data for the 'order' column
		Category.find(:all).each do |cur_cat|
			cur_cat[:sequence] = cur_cat[:lft]
			cur_cat.save
		end
		@actions += 'sequence column filled' + "\n"

		remove_column :categories, :lft
		remove_column :categories, :rgt
		@actions += 'nested-set columns dropped' + "\n"


		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 5 -> 6 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	# Drops the new columns, adds the old 'lft' and 'rgt' automatically-populated columns back in
	def self.down
		@actions = ''

		add_column :categories, :lft, :integer, :null => false, :default => 0
		add_column :categories, :rgt, :integer, :null => false, :default => 0
		@actions += 'nested-set columns added' + "\n"

		remove_column :categories, :sequence
		@actions += 'sequence column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 6 -> 5 complete'
	end
end
