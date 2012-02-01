module AdminHelper
	# returns some tooltip textual help for an item on a page
	def tooltip_text(page, item)
		@tooltips = YAML::load(File.open("#{RAILS_ROOT}/doc/tooltips.yml"))

		if @tooltips and @tooltips[page]
			tooltip = @tooltips[page][item]
		end

		if tooltip
			tooltip.gsub("'", "\\\\'").gsub('"', "")
		else
			nil
		end
	end

	# outputs HTML that creates a tooltip icon with a mouseover capability to show the correct
	# tooltip for the specified page and item
	def show_tooltip(page, item, custom_text = nil)
		if custom_text
			tooltip = custom_text.gsub("'", "\\\\'").gsub('"', "")
		else
			tooltip = tooltip_text(page, item)
		end

		if tooltip
			icon_width = @design_config[:sizes][:admin_icons_width].to_s
			icon_height = @design_config[:sizes][:admin_icons_height].to_s
			tooltip_options = @design_config[:options][:tooltip_options].to_s

			image_tag(
				"#{icon_path('help')}",
				{
					:alt => "Help",
					:size => "#{icon_width}x#{icon_height}",
					:class => "icon",
					:style => "margin-left: 4px;",
					:onmouseover => "return overlib('#{tooltip}'#{tooltip_options});",
					:onmouseout => "return nd();"
				}
			)
		else
			""
		end
	end

	# outputs HTML that creates an action icon, which is made up of a graphical icon next to a
	# text link, which both point to 'link_to_place'
	def action_icon (action_name, graphic_name, link_to_place)
		return_string = ""

		if @design_config[:options][:show_extra_admin_icons] and @design_config[:options][:show_extra_admin_icons] == 'yes'
			return_string = link_to(
				image_tag(
					icon_path(graphic_name),
					{
						:alt => action_name,
						:title => action_name,
						:size => "#{@design_config[:sizes][:admin_icons_width]}x#{@design_config[:sizes][:admin_icons_height]}",
						:class => "icon"
					}
				),
				link_to_place )
		end

		return_string + link_to(action_name, link_to_place)
	end
end
