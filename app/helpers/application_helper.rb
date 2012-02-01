# The methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	# gives the path for an icon image
	def icon_path(icon_name)
		"/images/icons/" + @design_config[:options][:icons_path] + "/#{icon_name}." + @design_config[:options][:icons_format]
	end

	def custom_error_messages_for(object_name, options = {})
		options = options.symbolize_keys
		object = instance_variable_get("@#{object_name}")
		unless object.errors.empty?
			content_tag("div",
#				content_tag(
#					options[:header_tag] || 'h2',
#					options[:title] || "#{pluralize(object.errors.count, 'error')} prohibited this #{object_name.to_s.gsub('_', ' ')} from being saved"
#				) +
				content_tag('p', 'There were problems with the following fields:') +
				content_tag('ul', object.errors.full_messages.collect { |msg| content_tag('li', msg) }),
				'id' => options[:id] || 'errorExplanation', 'class' => options[:class] || 'errorExplanation'
			)
		end
	end

	# Takes a string, and abbreviates the string to a specified length, adding '...' at the end if necessary.
	# The string is allowed to be 3 characters longer to allow for the '...' that we add.
	# if 'start' is true, it'll chop at the start of the string.  This feature was added but its intended
	# use was abandoned.
	def abbrev(in_string, max_length, start = false)
		if (in_string.length - 3) > max_length # So we don't end up making the string longer by chopping off 1-2 characters then adding 3.
			start ? ('...' + in_string.slice(-max_length, max_length)) : (in_string.slice(0, max_length) + '...')
		else
			in_string
		end
	end

	def rocket_cart_version(detailed = false)
		if detailed
			# this needs to be expanded to output the database schema version number as well
			'v1.4.1' #LONGVERSIONSTRING - LEAVE THIS COMMENT - USED BY OTHER SCRIPTS
		else
			'v1.4.1' #VERSIONSTRING - LEAVE THIS COMMENT - USED BY OTHER SCRIPTS
		end
	end

	# Return the <img> tag for a thumbnail image of the given product if available.
	def product_thumbnail(product, width = nil, height = nil)
		width ||= @design_config[:sizes][:category_page_thumbnail_width]
		height ||= @design_config[:sizes][:category_page_thumbnail_height]

		if product.image
			alt_text = product.image_alt_tag || product.image.caption
			image_tag("/product_images/thumbnail/#{product.image.id}/#{width}/#{height}", :class => "thumbnail", :size => "#{width}x#{height}", :alt => alt_text, :title => product.name)
		else
			"<table class=\"no-image\"><tr><td style=\"width: #{width - 2}px; height: #{height - 2}px;\">(No image available)</td></tr></table>"
		end
	end
end
