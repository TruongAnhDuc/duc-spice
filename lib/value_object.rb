# Note ".valid?" method  must occur on object for validates_associated
class ValueObject
	def initialize(attributes = nil)
		if attributes
			attributes.each do |key,value|
				send(key.to_s + '=', value)
			end
		end
		yield self if block_given?
	end
	
	def [](key)
		instance_variable_get("@#{key}")
	end
	
	def method_missing( method_id, *args )
		if md = /_before_type_cast$/.match(method_id.to_s)
			attr_name = md.pre_match
			return self[attr_name] if self.respond_to?(attr_name)
		end
		super
	end

protected 
	def raise_not_implemented_error(*params)
		ValidatingModel.raise_not_implemented_error(*params)
	end
	
	def self.human_attribute_name(attribute_key_name)
		attribute_key_name.humanize
	end
	
	def new_record?
		true
	end
	
	# these methods must be defined before include
	alias save raise_not_implemented_error
	alias update_attribute raise_not_implemented_error

public
	include ActiveRecord::Validations

protected 
	# the following methods must be defined after include so that they overide
	# methods previously included
	alias save! raise_not_implemented_error

	class << self
		def raise_not_implemented_error(*params)
			raise NotImplementedError
		end
	
		alias validates_uniqueness_of raise_not_implemented_error
		alias create! raise_not_implemented_error
		alias validate_on_create raise_not_implemented_error
		alias validate_on_update raise_not_implemented_error
		alias save_with_validation raise_not_implemented_error    
	end
end

require 'dispatcher'
class Dispatcher
	class << self
		if ! method_defined?(:form_original_reset_application!) 
			alias :form_original_reset_application! :reset_application!
			def reset_application!
				form_original_reset_application!
				Dependencies.remove_subclasses_for(ActiveForm) if defined?(ActiveForm)
			end
		end
	end
end
