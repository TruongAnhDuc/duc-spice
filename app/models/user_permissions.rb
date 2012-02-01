# Represents a user's permission level, and contains various functions for checking relative
# privileges and converting to symbols and strings, meaning you can do neat stuff like this:
#
#   if @user.permissions < :staff
#     ...
#   end
#
# Nifty, huh?
#
# The permission levels are:
# 0 - customer (default)
# 1 - Rocket Cart store manager (:staff)
# 2 - Rocket Cart store owner (:client)
# 3 - Avatar staff member (:admin)
# 4 - Avatar programmer (:deity)
class UserPermissions
	attr_reader :user_level

	def initialize(user_level = 0)
		if user_level.is_a? Symbol
			for k in 0..4
				if user_level == UserPermissions.new(k).to_sym
					@user_level = k
				end
			end
		else
			@user_level = user_level.to_i
		end
	end

	def to_s
		case @user_level
		when 4
			"$deity"
		when 3
			"Administrator (AVATAR)"
		when 2
			"Administrator"
		when 1
			"Staff Member"
		else
			"User"
		end
	end

	def to_i
		@user_level
	end

	def to_sym
		case @user_level
		when 4
			:deity
		when 3
			:admin
		when 2
			:client
		when 1
			:staff
		else
			:user
		end
	end

	def ==(other)
		self.to_i == UserPermissions.new(other).to_i
	end

	def <(other)
		self.to_i < UserPermissions.new(other).to_i
	end

	def >(other)
		self.to_i > UserPermissions.new(other).to_i
	end

	def <=(other)
		self.to_i <= UserPermissions.new(other).to_i
	end

	def >=(other)
		self.to_i >= UserPermissions.new(other).to_i
	end
end
