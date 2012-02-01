require File.dirname(__FILE__) + '/../test_helper'

# CAPTCHA - nobody can speel it, most oarsome word evar...
#
# we probably want more rigorous testing here sometime
class CaptchaTest < Test::Unit::TestCase

	def setup
		@cap = Captcha.new
	end

	# test that the basic CAPTCHA encode/decode functionalities are actually inverses
	def test_encode_decode
		# do the test 10 times to ensure there's some reliability in the way the rand() values
		# are handled
		10.times do
			test_code = @cap.generate_code

			encoded = @cap.encode(test_code)

			decoded = @cap.decode(encoded)

			assert_equal(test_code, decoded)

			assert_equal(true, @cap.check(test_code, encoded))
		end
	end
end
