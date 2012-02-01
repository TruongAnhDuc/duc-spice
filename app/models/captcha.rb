require 'gd2'

# Captcha: A Ruby port of our weak Captcha script.
# This implementation differs slightly from the PHP version but the encoding/decoding
# is compatible if you have a mixed-language site.

# To generate Captcha images you need to have the typewise_alpha.ttf font
# in the /config/ directory.
class Captcha
	attr_accessor :code_ref

	# Constructor
	def initialize
		self.code_ref = self.encode(self.generate_code)
	end

	# Generate a random code
	# Returns the code as a string.
	def generate_code
		# without any parameters, a combination of the time, PID and a sequence number is used.
		srand
		num = Array.new
		6.times do
			num << rand(10).to_i
		end
		num.join
	end

	# Encodes the number (I'd better not call it "encrypting")
	# The number is returned as a string.
	def encode(num)
		num = num.split(//) # turns the string into an array
		result = Array.new
		result.push(9 - num[0].to_i)
		1.upto(5) do |i|
			diff = num[i].to_i - num[i-1].to_i
			if diff < 0
				diff += 10
			end
			result << 9 - diff
		end
		result.reverse.join
	end

	# Undo the encoding.  Returns a string.
	def decode(num)
		num = num.split(//).reverse
		result = Array.new
		result << 9 - num[0].to_i
		1.upto(5) do |i|
			result << (result[i-1] + (9 - num[i].to_i)) % 10
		end
		result.join
	end

	# Check a code against a reference
	def check(code, ref)
		code == self.decode(ref)
	end

	# Create and return an image object.
	# send_image doesn't exist in this implementation: instead the controller calls create_image
	# then uses send_data to send it to the client (it seems that send_data isn't available in the
	# scope of the model!)
	def create_image(code)
		code = self.decode(code)
		angle = 5.degrees
		width = 80
		height = 25
		bg = GD2::Color[0xff, 0xff, 0xff]
		fg = GD2::Color[0x00, 0x00, 0x00]
		cap_image = GD2::Image::TrueColor.new(80, 25)
		cap_image.draw do |canvas|
			canvas.color = bg
			canvas.rectangle(0, 0, width - 1, height - 1, true)
			canvas.color = fg

			canvas.font = GD2::Font::TrueType.new(RAILS_ROOT + '/config/typewise_alpha.ttf', 14)
			box = canvas.font.bounding_rectangle(code, angle)
			# The API docs aren't exactly clear on how the coordinates are indexed.
			text_width = (box[:lower_right][0] - box[:lower_left][0]).abs
			text_height = (box[:upper_left][1] - box[:lower_left][1]).abs
			text_x = ((width - 1) - text_width) / 2 + 3 # The 3 is a fudge-factor.  mmmm, fudge....
			text_y = ((height - 1) + text_height) / 2 # The origin is at top-left
			canvas.move_to(text_x.to_i, text_y.to_i)
			canvas.text(code, angle)
		end

		cap_image
	end

end
