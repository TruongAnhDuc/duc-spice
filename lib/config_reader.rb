require 'yaml'

class ConfigReader
	attr_reader :options

# THIS SHOULD WORK! But if @filename is valid, it magically prepends a second path (to the same
# place, but without going through /lib. Which of course then breaks the path... RRRAAAGGGHHH!
# A beer for whoever can explain this absurd behaviour
#
# Note - it works just fine in script/console. BUT NOT IN THE APP. (wtfzomghaxbbq!)
	def initialize(filename)
		@filename = File.dirname(__FILE__) + '/' + filename

		@options = YAML::load(IO.read(@filename))
	end

	def [](key)
		@options[key]
	end

	def []=(key, val)
		@options[key] = val
	end

	def save(filename = nil)
		f = File.new(filename || @filename, 'w')
		f.write(YAML::dump(@options))
		f.close
	end
end
