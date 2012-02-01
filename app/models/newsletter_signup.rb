# Represents an email address/name that has signed up to receive newsletters

class NewsletterSignup < ActiveRecord::Base
	validates_uniqueness_of :email
	validates_presence_of :email, :first_name

	def to_s
		output = self.first_name
		if self.last_name
			output += " #{self.last_name}"
		end

		if output.include? ","
			output = "\"#{output}\""
		end

		"#{output} <#{self.email}>"
	end

	def name
		output = self.first_name
		if self.last_name
			output += " #{self.last_name}"
		end

		output
	end
end
