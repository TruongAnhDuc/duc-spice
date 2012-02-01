# This migration changes only data - it increments the 'sequence' values of categories by 1, so
# that they now start with 1 (rather than 0). It also takes the opportunity it reset sequence
# values to valid sequences (no gaps)

class FixCategorySequences < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# No models needed as we are not migrating data (it's impossible to update the hash).

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.recursively_fix (parent_id, sequence_shift)
		children = Category.find(:all, :conditions => "parent_id = #{parent_id}", :order => "sequence ASC")

		if children
			cur_sequence = 1
			children.each do |cur_child|
				cur_child.sequence = cur_sequence
				cur_sequence += sequence_shift
				cur_child.save

				recursively_fix(cur_child.id, sequence_shift)
			end
		end
	end

	def self.up
		@actions = ''

		root_cat = Category.find(1)
		root_cat.sequence = 1
		root_cat.save

		self.recursively_fix(1, 1)

		@actions += 'Category sequence data fixed' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 18 -> 19 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		root_cat = Category.find(1)
		root_cat.sequence = 0
		root_cat.save

		self.recursively_fix(1, -1)

		@actions += 'Category sequence data crapified' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 19 -> 18 complete'
	end
end
