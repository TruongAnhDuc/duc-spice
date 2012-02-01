# This migration changes the database schema by adding a `form_name` field to the
# `static_pages` table. It also adds the existing built-in static pages into the table
# so they can be administrated.

# NOTE THAT MIGRATING DOWN THROUGH THIS STEP WILL DUMP DATA PERMANENTLY

class BuiltInStaticPages < ActiveRecord::Migration

	###############################################################################
	## MODELS
	###############################################################################

	# Represents a static page. These are all stored in the database so that Rocket Cart can do its
	# dynamic stuff on every page without having to duplicate templates and so forth.
	class StaticPage < ActiveRecord::Base
	end

	###############################################################################
	## MIGRATION METHODS (UP)
	###############################################################################

	def self.up
		@actions = ''

		add_column :static_pages, :form_name, :string, :limit => 32

		@actions += 'form_name column added' + "\n"

		@contact_us_form = StaticPage.new
		@contact_us_form.name = "Contact Us"
		@contact_us_form.path = "/contact-us"
		@contact_us_form.title = "Contact Us"
		@contact_us_form.body = "<h1>Enquiry Form</h1>\n<p>Please fill in the form below to email us with your comments, suggestions or enquiries.</p>"
		@contact_us_form.form_name = "contact"
		@contact_us_form.save

		@home_page = StaticPage.new
		@home_page.name = "Home Page"
		@home_page.path = "/"
		@home_page.title = "Home Page"
		@home_page.body = "<h1>Try out the Rocket Cart shopping solution</h1>\n<p>By browsing around the Rocket Cart demo shop, you can get a very good idea of how your own Rocket Cart shop will shape up online. These are some of the things you can try out:</p>\n<ul>\n	<li>View product categories and individual products</li>\n	<li>View enlarged product pictures, product descriptions and options</li>\n	<li>Add to, change and remove items from your shopping cart</li>\n	<li>Create and edit dummy orders</li>\n	<li>Go to the checkout and create your shopper account</li>\n</ul>\n<p><a href=\"/products\">Start browsing our demo shop</a></p>\n<p>Please note: Our Rocket Cart demo shop looks similar to how a stand-alone Rocket Cart shop might look. Rocket Cart can also be incorporated into an existing Web site using shop design templates or a customised design tailored to closely match an existing Web site.</p>\n<p><strong>Why you should choose Rocket Cart as your online shop</strong></p>\n<ul>\n	<li>It is designed to be found by search engines</li>\n	<li>It offers a secure and easy shopping process</li>\n	<li>It offers shoppers clear navigation and straightforward functionality</li>\n	<li>It offers you an easy to manage, affordable way to sell products online</li>\n</ul>\n<p><strong>Rocket Cart (Back End) Demo</strong></p>\n<p>You can get a comprehensive idea of how the back end of Rocket Cart works by playing around in our back end demo (by back end, we mean the shop's management area).</p>\n<p><strong><a href=\"http://www.rocketcart.co.nz/online-shopping-cart-software.html\">Contact us</a> for a temporary login.</strong></p>\n<p><strong>You will be given access to the Rocket Cart demo within 12 working hours.</strong><p>\n"
		@home_page.form_name = "home"
		@home_page.save

		@products_overview = StaticPage.new
		@products_overview.name = "Products Overview"
		@products_overview.path = "/products-overview"
		@products_overview.title = "Products Overview"
		@products_overview.body = "<h1>Our Products</h1>\n<p>Click on a thumbnail to view more information about a particular product.</p>\n<p>Click here to <a href=\"/cart/show\">view cart</a>.</p>"
		@products_overview.form_name = "overview"
		@products_overview.save

		@products_overview = StaticPage.new
		@products_overview.name = "Search"
		@products_overview.path = "/search"
		@products_overview.title = "Search"
		@products_overview.body = "<h1>Search for Products</h1>"
		@products_overview.form_name = "search"
		@products_overview.save

		@actions += 'built-in static pages added' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 24 -> 25 complete'
	end

	###############################################################################
	## MIGRATION METHODS (DOWN)
	###############################################################################

	def self.down
		@actions = ''

		execute 'DELETE FROM static_pages WHERE `form_name` IS NOT NULL'

		@actions += 'built-in static pages removed' + "\n"

		remove_column :static_pages, :form_name

		@actions += 'form_name column dropped' + "\n"

		# SHOW DEBUG
		if @actions != ''
			puts @actions
		else
			puts 'No actions needed!' + "\n"
		end
		puts 'Migration from schema 25 -> 24 complete'
	end
end
