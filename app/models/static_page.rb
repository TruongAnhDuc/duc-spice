# Represents a static page. These are all stored in the database so that Rocket Cart can do its
# dynamic stuff on every page without having to duplicate templates and so forth.
class StaticPage < ActiveRecord::Base
	has_and_belongs_to_many :features, :join_table => 'features_static_pages', :conditions => "until IS NULL OR until >= '#{Date.today.to_s}'"

	# Display name for the category in a select box (admin area use only).
	def option_label
		name + ' (' + path + ')'
	end
end
