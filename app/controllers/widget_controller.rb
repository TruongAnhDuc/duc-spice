# Contains functions for small graphical components showable on the site - eg login area, currency
# choosing area etc
class WidgetController < ApplicationController
	layout :none

	# Require the user to be registered and logged in before checking out.
	before_filter :authorise
	before_filter :require_authorisation, :only => :checkout

	def user_manager
	end
end
