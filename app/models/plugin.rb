# Abstract class representing a plugin. At the moment, nothing else uses this interface except the PaymentModule class, but it's got
# a bunch of stuff relating to how to configure and update options. I figured the extra flexibility was worth it.

class Plugin < ActiveRecord::Base
	has_many :parameters, :class_name => 'PluginParameter', :dependent => :delete_all

	# Updates the configuration stored in the YAML file whose location is given by the +config+ instance variable.
	def configure(options)
		if !config.nil?
			current_options = YAML::load(IO.read(config))
			current_options.update(options)
			f = File.new(config, 'w')
			f.write(YAML::dump(current_options))
			f.close
		end
	end

	class << self
		# Gets the default PaymentModule (deprecated; use +PaymentModule.default+ directly instead).
		# I think this is a hangover from when I thought ActiveRecord subclasses had to be in the same
		# file as their superclass.
		def payment_module
			PaymentModule.default
		end
	end
end
