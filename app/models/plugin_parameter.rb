# This class has been superceded by the vastly more efficient and flexible method of storing configuration in YAML files instead.

class PluginParameter < ActiveRecord::Base
	belongs_to :plugin
	
end
