# Class for sending user-level emails.

class Postman < ActionMailer::Base
	self.template_root = RAILS_ROOT + '/custom'
	self.default_content_type = 'text/html'

	# Sends an order confirmation email.
	def confirm(config, order)
		@subject       = "#{config[:application][:name][:value]} Order Confirmation: Order \##{order.id}"
		@recipients    = "#{order.user} <#{order.user.email}>"
		@from          = "#{config[:application][:name][:value]} <#{config[:emails][:shipping][:value]}>"
		@sent_on       = Time.now
		@body['order'] = order
		@body['items'] = order.items
		@body['team_name'] = config[:application][:team_name][:value]
	end

	# Sends a shipping notification email.
	def shipped(config, order)
		@subject       = "#{config[:application][:name][:value]} Shipping Notification: Order \##{order.id}"
		@recipients    = "#{order.user} <#{order.user.email}>"
		@from          = "#{config[:application][:name][:value]} <#{config[:emails][:shipping][:value]}>"
		@sent_on       = Time.now
		@body['order'] = order
		@body['items'] = order.items
		@body['team_name'] = config[:application][:team_name][:value]
	end

	# Sends a notification for the given order to the store administrator.
	def sent(config, order)
		@subject       = "#{config[:application][:name][:value]} Order Notification: Order \##{order.id}"
		@recipients    = config[:emails][:admin][:value]
		@from          = "#{order.user} <#{order.user.email}>"
		@sent_on       = Time.now
		@body['order'] = order
		@body['items'] = order.items
		@body['delivery_address'] = order.delivery_address ? order.delivery_address : nil
		@body['billing_address'] = order.billing_address ? order.billing_address : nil
		@body['config'] = config
	end

	# Sends a general enquiry from a 'contact us'-type form.
	def contact(config, name, email, comments)
		content_type 'text/plain'

		@subject       = "Enquiry from #{config[:application][:name][:value]} Web site"
		@recipients    = config[:emails][:admin][:value]
		@from          = "#{name} <#{email}>"
		@sent_on       = Time.now
		@body['name']  = name
		@body['email'] = email
		@body['comments'] = comments
	end

	# Sends the user's new password to them (from 'forgotten password' form).
	def password(config, email, name, password)
		@subject       = "Your new #{config[:application][:name][:value]} password"
		@recipients    = email
		@from          = "#{config[:application][:name][:value]} <#{config[:emails][:password_reset][:value]}>"
		@sent_on       = Time.now
		@body['name']  = name
		@body['password'] = password
		@body['team_name'] = config[:application][:team_name][:value]
	end

	# Sends the users's new password to them with a message to confirm their successful
	# application for a wholesale account (from admin customers area)
	def wholesale_approved(config, customer)
		@subject       = "Your wholesale account with #{config[:application][:name][:value]} is now ready"
		@recipients    = "#{customer.to_s} <#{customer[:email]}>"
		@from          = "#{config[:application][:name][:value]} <#{config[:emails][:default][:value]}>"
		@sent_on       = Time.now
		@body['name']  = customer.to_s
		@body['website']  = config[:application][:name][:value]
		@body['password'] = customer.password
		@body['team_name'] = config[:application][:team_name][:value]
		@body['url'] = config[:application][:url][:value]
	end

	# Alerts the administrator to a user account that has applied for access to the wholesale
	# area of the website
	def wholesale_application(config, customer)
		content_type 'text/plain'

		@subject       = "Wholesaler application from #{customer.to_s}"
		@recipients    = config[:emails][:admin][:value]
		@from          = "#{customer.to_s} <#{customer[:email]}>"
		@sent_on       = Time.now
		@body['name']  = customer.to_s
		@body['email'] = customer[:email]
		@body['id'] = customer[:id]
		@body['url'] = config[:application][:url][:value]
	end
end
