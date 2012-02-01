require 'yaml'

class Configurator
	attr_reader :options

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
		f = File.new(filename || @filename, "w")
		f.write(YAML::dump(@options))
		f.close
	end

	class << self
		@@filename = File.dirname(__FILE__) + "/../config/rocketcart.yml"

		def instance
			@@my_instance ||= Configurator.new(@@filename)
		end

		def [](key)
			self.instance[key]
		end

		def []=(key, val)
			self.instance[key] = val
		end

		def save
			self.instance.save(@@filename)
		end

		def force_reload
			@@my_instance = nil
		end
	end
end
