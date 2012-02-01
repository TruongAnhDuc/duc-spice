require File.dirname(__FILE__) + '/../test_helper'
require 'static_pages_controller'

# Re-raise errors caught by the controller.
class StaticPagesController; def rescue_action(e) raise e end; end

class StaticPagesControllerTest < Test::Unit::TestCase
	fixtures :users, :static_pages, :categories

	def setup
		@controller = StaticPagesController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end

	def test_static_page_fixtures
		assert_equal(static_pages(:aboutus).name, 'About Us')
	end

	# no URL is given, no static page should be rendered
	def test_bad_static_page
		get :index

		assert_response :success

		assert_not_nil assigns(:page_not_found)
	end

	# test the correct static page is shown (URL is given)
	def test_static_page
# it appears this style of interaction is deprecated, and doesn't work (without adding in more
# non-obvious stuff...)
#		@request.path = '/contact-us'
#		@request.action = :contact_us
#		response = StaticPagesController.process_test(@request)
		@request.path = '/about-us'
		@request.action = :index
# gives error - renders a page, but @static_page isn't set? :?
#		response = StaticPagesController.process_test(@request)

#		assert_response :success

# B0RKEN!@
#assert_not_nil assigns(:static_page)

#assert_nil assigns(:static_page)

#		static_page = StaticPage.find(@static_page)
#		assert_equal(static_page.name, users(:aboutus).name)
#		assert_equal(static_page.title, users(:aboutus).title)
	end

	def test_contact_us
		# first try just loading the page - nothing should be sent etc, just some instance
		# variables get set
		get :contact_us

		assert_response :success

		assert_not_nil assigns(:your_email)
		assert_not_nil assigns(:your_name)
		assert_not_nil assigns(:your_comments)

		assert_equal('', assigns(:your_email))
		assert_equal('', assigns(:your_name))
		assert_equal('', assigns(:your_comments))

		# now gear up and send a comment - but with an invalid CAPTCHA, which should get caught
		cap = Captcha.new
		the_code = cap.generate_code
		the_code_ref = cap.encode(the_code)

		post :contact_us, {:send => 'Send', :code => the_code, :code_ref => (the_code_ref + '41'), :name => 'Test', :email => 'test@example.com', :comments => 'a test comment'}

		assert_response :success

		assert_not_nil assigns(:code_error)
		assert_equal(true, assigns(:code_error))
		assert_template 'contact_us'

		# now try sending a valid CAPTCHA along with a comment.
		post :contact_us, {:send => 'Send', :code => the_code, :code_ref => the_code_ref, :name => 'Test', :email => 'test@example.com', :comments => 'a test comment'}

		assert_response :success

		# an email should have been sent, and the 'thanks' template rendered
		assert_equal(false, assigns(:code_error))
		assert_template 'thanks'
	end

	def test_forgotten_password
		# check just the loading of the page
		get :forgotten_password

		assert_response :success

		assert_nil assigns(:user)

		assert_template 'forgotten_password'

		# now check sending the page with an email that doesn't exist in the DB
		post :forgotten_password, {:send => 'Send', :email => users(:devil).email + '.au'}

		assert_response :success

		assert_nil assigns(:user)

		assert_nil assigns(:new_password)

		assert_equal(assigns(:pw_changed), false)

		assert_template 'forgotten_password'

		# now check sending the page with an email that DOES exist in the DB
		post :forgotten_password, {:send => 'Send', :email => users(:devil).email}

		assert_response :success

		assert_not_nil assigns(:user)

		assert_equal(assigns(:user).id, users(:devil).id)
		assert_equal(assigns(:user).first_name, users(:devil).first_name)
		assert_equal(assigns(:user).last_name, users(:devil).last_name)
		assert_equal(assigns(:user).email, users(:devil).email)

		assert_not_nil assigns(:new_password)

		assert_equal(assigns(:user).hashed_password, User.hash_password(assigns(:new_password)))

		assert_template "forgotten_password"

		assert_equal(assigns(:pw_changed), true)
	end
end
