# Represents a piece of information that a Product may have added to it - is the abstract class for
# a QuirkValue. YES THIS IS A WEIRD NAME - but I had to find a synonym for 'Attribute', which you
# can't use (reserved word in Active Record :( ), and 'property' just sounds lame. This should be
# referred to in the front-end as an 'Attribute', however.
class Quirk < ActiveRecord::Base
	belongs_to :product_type
	has_many :quirk_values

	acts_as_list :scope => :product_type_id
end

class TextQuirk < Quirk
end

class HtmlQuirk < Quirk
end

class IntegerQuirk < Quirk
end

class BooleanQuirk < Quirk
end

class UrlQuirk < Quirk
end

class ImageQuirk < Quirk
end
