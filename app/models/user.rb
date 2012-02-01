require 'digest/sha1'
require 'digest/md5'

# Represents any user of the system. The default User has customer-level permissions only.

class User < ActiveRecord::Base
	has_many :orders
	has_many :reviews
	composed_of :permissions, :class_name => "UserPermissions", :mapping => [ :user_level, :user_level ]

	attr_accessor :password
	attr_accessor :password_confirmation
	attr_protected :hashed_password
	validates_uniqueness_of :email
	validates_presence_of :email, :first_name, :last_name

	def validate
		# password cannot be blank
		if (self.password && !self.password.empty?) || (self.password_confirmation && !self.password_confirmation.empty?)
			if self.password_confirmation == self.password
				self.hashed_password = self.hash_password(self.password)
			else
				errors.add("password", "does not match confirmation password")
			end
		else
			if self.new_record?
				errors.add("password", "must be filled out")
			end
		end
	end

	def after_save
		self.password = nil
		self.password_confirmation = nil
	end

	def to_s
		"#{self.first_name} #{self.last_name}"
	end

	# Encrypts the user's password for database storage.
	def hash_password(password)
		User.hash_password(password, self.hash_algorithm)
	end

	def self.hash_algorithm_to_i(algorithm)
		case algorithm
			when "MD5"
				1
			when "SHA1"
				2
			else
				2
		end
	end

	# Encrypts the user's password for database storage, using an optionally specified algorithm
	def self.hash_password(password, algorithm = 2)
		case algorithm
			when 1
				Digest::MD5.hexdigest(password)
			when 2
				Digest::SHA1.hexdigest(password)
			else
				Digest::SHA1.hexdigest(password)
		end
	end

	def self.list_levels
		[:user, :staff, :client, :admin, :deity]
	end
end
