# Placeholder for a payment module. The payment modules themselves are currently implemented as external modules, mostly
# to avoid having to rewrite third-party PHP code (such as, for example, the Payment Express Hosted Payments Page stuff).
# The payment modules themselves are in +www/public/payments+.

class PaymentModule < Plugin
	# Ensures that only one PaymentModule can be active at any one time.
	def active=(value)
		PaymentModule.update_all 'active = 0', "id <> #{id}"
		super
	end

	class << self
		# Returns the default PaymentModule.
		def default
			PaymentModule.find(:first, :conditions => 'active = 1') || none
		end

		# Dummy null PaymentModule, for testing, or situations where no payment is required.
		def none
			PaymentModule.new({
				:name => '(none)',
				:description => 'Users will not be asked to enter payment details when making an order.'
			})
		end
	end
end