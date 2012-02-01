# Represents a product category.
# This class contains a number of methods included to fix the problem that ActsAsNestedSet and
# ActsAsList don't play nicely together under certain conditions.

class Category < ActiveRecord::Base
	acts_as_tree :order => 'sequence' # note that sequence starts at 1, NOT 0
# No longer used
#	acts_as_nested_set :scope => '1=1'
	has_and_belongs_to_many :products, :join_table => 'categories_products', :conditions => "available = 1 AND (expiry_date IS NULL OR expiry_date >= '#{Date.today.to_s}')"

	has_and_belongs_to_many :features, :join_table => 'categories_features', :conditions => "until IS NULL OR until >= '#{Date.today.to_s}'"

	validates_presence_of :name

	def list_scope_condition #:nodoc:
		if parent_id.nil?
			'parent_id IS NULL'
		else
			"parent_id=#{parent_id}"
		end
	end

	# Makes child categories and products children of this categories' parent, so they're not
	# orphaned by the delete. Must be called manually, as Rails will auto-delete children before
	# the parent (so the before_destroy callback is useless - nice one Rails!)
	def move_children_up
		# SAVE CHILD CATEGORIES

		# Save the largest sequence number, for use later when inserting children as siblings
		max_seq = 1
		self.siblings.each do |cur_sib|
			if cur_sib.sequence > max_seq
				max_seq = cur_sib.sequence
			end
		end

		self.children.each do |child|
			child.path = (self.parent.path ? self.parent.path + '/' : '') + child.filename
			child.parent = self.parent
			child.sequence = max_seq
			max_seq += 1
			child.save
		end

		# SAVE CHILD PRODUCTS
		child_products = self.products
		child_products.each do |cur_product|
			cur_product.categories.delete(self)
			cur_product.categories << self.parent
			cur_product.save
		end
	end

	# Seals any 'hole' in the sequence
	def after_destroy
		self.siblings.each do |cur_sib|
			if cur_sib.sequence > self.sequence
				cur_sib.sequence -= 1
				cur_sib.save
			end
		end
	end

	# Calculates the correct URL path based on the name of the category and its parents.
	def before_save
		self.name ||= ''
		self.filename ||= self.name.downcase.gsub(/[^a-z0-9]+/, '-')
		if self.parent.nil?
			self.path = filename
		else
			self.path = self.parent.path + '/' + self.filename
		end

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

	# Display name for the category in a select box (admin area use only).
	def option_label
		name + ' (' + path + ')'
	end

	# Returns the list of ancestors back to the root, for displaying a breadcrumb trail to the
	# current category.
	def breadcrumbs
		self.parent.nil? ? [self] : self.parent.breadcrumbs + [self]
	end

	# DEPRECATED: this will break if #0 is deleted
	def first? #:nodoc:
		sequence == 1
	end

	# DEPRECATED: this assumes contiguous sequences
	def last? #:nodoc:
		Category.count(:id, :conditions => list_scope_condition + ' AND sequence>' + sequence.to_s).zero?
	end

	def higher_item #:nodoc:
		Category.find(:first, :conditions => [ list_scope_condition + ' AND sequence < ' + sequence.to_s ], :order => 'sequence DESC', :limit => 1, :offset => 0)
	end

	def lower_item #:nodoc:
		Category.find(:first, :conditions => [ list_scope_condition + ' AND sequence > ' + sequence.to_s ], :order => 'sequence ASC', :limit => 1, :offset => 0)
	end

	def move_higher #:nodoc:
		h = higher_item
		if h
			Category.transaction do
				temp_sequence = self.sequence
				self.sequence = h.sequence
				h.sequence = temp_sequence
				h.save
				self.save
			end
		end
	end

	def move_lower #:nodoc:
		l = lower_item
		if l
			Category.transaction do
				temp_sequence = self.sequence
				self.sequence = l.sequence
				l.sequence = temp_sequence
				l.save
				self.save
			end
		end
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
