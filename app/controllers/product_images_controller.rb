# Controller handling everything to do with the storge and retrieval of product images.
class ProductImagesController < ApplicationController
	# Cache thumbnail images. Caching only happens when the site is in production mode, so make
	# sure you do that. Note that cached images are served with the WRONG mimetype - this is a
	# well known limitation in the Rails caching mechanism :(.
	caches_action :image
	caches_action :thumbnail

	# We don't need this stuff for images!
	skip_before_filter :get_preferred_currency

	# Display an image straight from the database.
	def image
		begin
			@image = Image.find(params[:id])
		rescue ActiveRecord::RecordNotFound
			render :text => "Image ##{params[:id].to_s} not found"
		else
			send_data(@image.data,
				:filename => @image.filename,
				:type => @image.content_type,
				:disposition => 'inline')
		end
	end

	# Display a thumbnail of a given image. Takes the following request parameters:
	# * +id+ - ID of the image to display
	# * +mode+ - one of either +stretch+, +fit+ or +crop+ (see ProductImage for details)
	# * +width+ and +height+ - dimensions of the thumbnail
	def thumbnail
		begin
			@image = Image.find(params[:id])
		rescue ActiveRecord::RecordNotFound
			render :text => "Image ##{params[:id].to_s} not found"
		else
			# Can probably replace this with a call to to_sym(), but why fix what ain't broke?
			scaling_mode = case params[:mode]
			when 'stretch' then :stretch
			when 'fit'     then :fit
			when 'crop'    then :crop
			else                :fit
			end
			@thumbnail = @image.thumbnail(params[:width], params[:height], scaling_mode)
			if @thumbnail.kind_of? Thumbnail
				send_data(@thumbnail.data,
					:filename => @thumbnail.filename,
					:type => @thumbnail.content_type,
					:disposition => 'inline')
			else
				render :text => @thumbnail.inspect
			end
		end
	end

	# Display a cropped thumbnail of a given image. Takes the following request parameters:
	# * +id+ - ID of the product whose image you want to display
	# * +width+ and +height+ - dimensions of the thumbnail
	def cropped_thumb
		begin
			@image = Image.find_by_product_id(params[:id])

			the_width = 16
			the_height = 20
#			if (params[:option_value])
#				the_product = Product.find(params[:id])
#				option_values = the_product.option_values
#				if (option_values[0][:id] == params[:option_value].to_i)
#					the_width = 17
#					the_height = 22
#				end
#			end

		rescue ActiveRecord::RecordNotFound
			render :text => "Image ##{params[:id].to_s} not found"
		else
			# Can probably replace this with a call to to_sym(), but why fix what ain't broke?
			@thumbnail = @image.cropped_thumbnail(the_width, the_height)
			if @thumbnail.kind_of? Thumbnail
				send_data(@thumbnail.data,
					:filename => @thumbnail.filename,
					:type => @thumbnail.content_type,
					:disposition => 'inline')
			else
				render :text => @thumbnail.inspect
			end
		end
	end

	# Shows the full-size image, probably in a popup window as a result of a user clicking a thumbnail or somesuch.
	#
	# <b>Template:</b> <tt>product_images/show.rhtml</tt>
	#
	# <b>Todo:</b> Add a caption of some kind to the image.
	def show
		begin
			@image = Image.find(params[:id])
		rescue ActiveRecord::RecordNotFound
			render :text => "Image ##{params[:id].to_s} not found"
		end
	end
end
