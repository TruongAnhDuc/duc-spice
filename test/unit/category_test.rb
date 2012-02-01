require File.dirname(__FILE__) + '/../test_helper'

# Tests of Categories (organisational unit for Products)
class CategoryTest < Test::Unit::TestCase
	fixtures :products, :categories, :categories_products, :categories_features

	def setup
		@cap = Captcha.new
	end

	# test that the 'move all children up' method works
	def test_category_reordering
		livestock_cat = Category.find(categories(:livestock).id)

		livestock_cat.move_children_up

		pigs_cat = Category.find(categories(:pigs).id)

		assert_not_equal(pigs_cat[:parent_id], livestock_cat.id)
		assert_equal(pigs_cat[:parent_id], categories(:root).id)

		dogs_cat = Category.find(categories(:dogs).id)

		assert_not_equal(dogs_cat[:parent_id], livestock_cat.id)
		assert_equal(dogs_cat[:parent_id], categories(:root).id)

		cats_cat = Category.find(categories(:cats).id)

		assert_not_equal(cats_cat[:parent_id], livestock_cat.id)
		assert_equal(cats_cat[:parent_id], categories(:root).id)
	end

	# test that breadcrumb generation returns the correct array of Categories
	def test_breadcrumbs
		root_breadcrumb = categories(:root).breadcrumbs

		assert_equal([categories(:root)], root_breadcrumb)

		livestock_breadcrumb = categories(:livestock).breadcrumbs

		assert_equal(livestock_breadcrumb.length, 2)
		assert_equal(livestock_breadcrumb[0], categories(:root))
		assert_equal(livestock_breadcrumb[1], categories(:livestock))

		pigs_breadcrumb = categories(:pigs).breadcrumbs

		assert_equal(pigs_breadcrumb.length, 3)
		assert_equal(pigs_breadcrumb[0], categories(:root))
		assert_equal(pigs_breadcrumb[1], categories(:livestock))
		assert_equal(pigs_breadcrumb[2], categories(:pigs))

		dogs_breadcrumb = categories(:dogs).breadcrumbs

		assert_equal(dogs_breadcrumb.length, 3)
		assert_equal(dogs_breadcrumb[0], categories(:root))
		assert_equal(dogs_breadcrumb[1], categories(:livestock))
		assert_equal(dogs_breadcrumb[2], categories(:dogs))

		cats_breadcrumb = categories(:cats).breadcrumbs

		assert_equal(cats_breadcrumb.length, 3)
		assert_equal(cats_breadcrumb[0], categories(:root))
		assert_equal(cats_breadcrumb[1], categories(:livestock))
		assert_equal(cats_breadcrumb[2], categories(:cats))
	end

	# ensure the first? and last? boolean methods are working
	def test_first_last
		assert_equal(true, categories(:root).first?)
		assert_equal(true, categories(:livestock).first?)
		assert_equal(false, categories(:utilities).first?)
		assert_equal(true, categories(:pigs).first?)
		assert_equal(false, categories(:dogs).first?)
		assert_equal(false, categories(:cats).first?)

		assert_equal(true, categories(:root).last?)
		assert_equal(false, categories(:livestock).last?)
		assert_equal(true, categories(:utilities).last?)
		assert_equal(false, categories(:pigs).last?)
		assert_equal(false, categories(:dogs).last?)
		assert_equal(true, categories(:cats).last?)
	end

	# ensure the higher/lower _item methods are working
	def test_next_cat
		assert_nil categories(:root).higher_item
		assert_nil categories(:pigs).higher_item
		assert_equal(categories(:pigs), categories(:dogs).higher_item)
		assert_equal(categories(:dogs), categories(:cats).higher_item)

		assert_nil categories(:root).lower_item
		assert_equal(categories(:dogs), categories(:pigs).lower_item)
		assert_equal(categories(:cats), categories(:dogs).lower_item)
		assert_nil categories(:cats).lower_item
	end

	# ensure sequence numbers retain their integrity despite insertions, deletions etc
	def test_sequences
		cows_cat = Category.new({
			:parent_id => categories(:livestock).id,
			:name => 'Cows'
		})
		cows_cat.save
		horses_cat = Category.new({
			:parent_id => categories(:livestock).id,
			:name => 'Horses'
		})
		horses_cat.save

		cows_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cows'")
		assert_equal(4, cows_cat.sequence)
		horses_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Horses'")
		assert_equal(5, horses_cat.sequence)

		# do a near-end deletion
		Category.destroy(cows_cat.id)

		pigs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Pigs'")
		assert_equal(1, pigs_cat.sequence)
		dogs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Dogs'")
		assert_equal(2, dogs_cat.sequence)
		cats_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cats'")
		assert_equal(3, cats_cat.sequence)
		cows_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cows'")
		assert_nil cows_cat
		horses_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Horses'")
		assert_equal(4, horses_cat.sequence)

		# do a near-beginning deletion
		Category.destroy(dogs_cat.id)

		pigs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Pigs'")
		assert_equal(1, pigs_cat.sequence)
		dogs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Dogs'")
		assert_nil cows_cat
		cats_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cats'")
		assert_equal(2, cats_cat.sequence)
		cows_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cows'")
		assert_nil cows_cat
		horses_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Horses'")
		assert_equal(3, horses_cat.sequence)
	end

	# ensure sequence numbers retain their integrity despite insertions, deletions etc. This
	# method adds the move_children_up() call which controllers will be using
	def test_sequences_with_move_children
		cows_cat = Category.new({
			:parent_id => categories(:livestock).id,
			:name => 'Cows'
		})
		cows_cat.save
		horses_cat = Category.new({
			:parent_id => categories(:livestock).id,
			:name => 'Horses'
		})
		horses_cat.save

		cows_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cows'")
		assert_equal(4, cows_cat.sequence)
		horses_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Horses'")
		assert_equal(5, horses_cat.sequence)

		# do a near-end deletion
		cows_cat.move_children_up()
		Category.destroy(cows_cat.id)

		pigs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Pigs'")
		assert_equal(1, pigs_cat.sequence)
		dogs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Dogs'")
		assert_equal(2, dogs_cat.sequence)
		cats_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cats'")
		assert_equal(3, cats_cat.sequence)
		cows_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cows'")
		assert_nil cows_cat
		horses_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Horses'")
		assert_equal(4, horses_cat.sequence)

		# do a near-beginning deletion
		dogs_cat.move_children_up()
		Category.destroy(dogs_cat.id)

		pigs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Pigs'")
		assert_equal(1, pigs_cat.sequence)
		dogs_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Dogs'")
		assert_nil cows_cat
		cats_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cats'")
		assert_equal(2, cats_cat.sequence)
		cows_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Cows'")
		assert_nil cows_cat
		horses_cat = Category.find(:first, :conditions => "parent_id = #{categories(:livestock).id} AND name = 'Horses'")
		assert_equal(3, horses_cat.sequence)
	end

	def test_move_higher
		pigs_cat = Category.find(categories(:pigs).id)
		dogs_cat = Category.find(categories(:dogs).id)
		cats_cat = Category.find(categories(:cats).id)

		# try moving something that was first higher
		assert_equal(true, pigs_cat.first?)
		assert_equal(false, dogs_cat.first?)

		pigs_cat.move_higher

		dogs_cat.reload
		assert_equal(true, pigs_cat.first?)
		assert_equal(false, dogs_cat.first?)

		# now try moving something that was last higher

		assert_equal(false, dogs_cat.last?)
		assert_equal(true, cats_cat.last?)

		cats_cat.move_higher

		dogs_cat.reload
		assert_equal(false, cats_cat.last?)
		assert_equal(true, dogs_cat.last?)
	end

	def test_move_lower
		pigs_cat = Category.find(categories(:pigs).id)
		dogs_cat = Category.find(categories(:dogs).id)
		cats_cat = Category.find(categories(:cats).id)

		# try moving something that was last lower
		assert_equal(false, dogs_cat.last?)
		assert_equal(true, cats_cat.last?)

		cats_cat.move_lower

		dogs_cat.reload
		assert_equal(false, dogs_cat.last?)
		assert_equal(true, cats_cat.last?)

		# now try moving something that was first lower
		assert_equal(true, pigs_cat.first?)
		assert_equal(false, dogs_cat.first?)

		pigs_cat.move_lower

		dogs_cat.reload
		assert_equal(false, pigs_cat.first?)
		assert_equal(true, dogs_cat.first?)
	end
end
