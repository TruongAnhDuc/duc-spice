# Represents a multiple-choice option for an Option that uses them.

class Value < ActiveRecord::Base
	belongs_to :option
	acts_as_list :order => 'position'

end
