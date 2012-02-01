require File.dirname(__FILE__) + '/../test_helper'
require 'products_controller'

# Re-raise errors caught by the controller.
class ProductsController; def rescue_action(e) raise e end; end

class ProductsControllerTest < Test::Unit::TestCase
	fixtures :users, :categories

	def setup
		@controller = ProductsController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end

	# test users can login
	def test_good_login
		post :home, :login => 'login', :email => 'god@example.com', :password => 'betterthanyou'
		assert_response :success

		# make sure the user_id is stored in the session
		assert_not_nil(session[:user_id])
		user = User.find(session[:user_id])
		assert_equal 'deity.family', user.last_name
	end

	# test invalid users can't login
	def test_bad_login
		post :home, :login => 'login', :email => 'god@example.com', :password => 'worsethanyou'
		assert_response :success

		# make sure the user_id is nil in the session
		assert_nil(session[:user_id])
	end

	# test non-users aren't logged in
	def test_no_login
		get :home
		assert_response :success

		# make sure the user_id is nil in the session
		assert_nil(session[:user_id])
	end
end
