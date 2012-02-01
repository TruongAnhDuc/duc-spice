require 'gd2'

# Stores a product image in the database.

class Image < ActiveRecord::Base
	belongs_to :product
	has_many :thumbnails, :class_name => 'Thumbnail', :foreign_key => 'thumbnail_of'

	validates_format_of :content_type, :with => /^image/,
		:message => 'image format not recognised'

	def image=(image_field)
		self.filename = image_field.original_filename.downcase.gsub(/[^\w\.]+/, '-')
		self.content_type = image_field.content_type.chomp
		img_data = image_field.read
		img = GD2::Image::load(img_data)
		s = [ img.width.to_f / 512.0, img.height.to_f / 512.0 ].max
		if s > 1.0
			img.resize! img.width / s, img.height / s
		end
		self.data = img.jpeg(80)
		self.width = img.width
		self.height = img.height
	end

	# Returns an image tag for a thumbnail of this image. Scaling modes are as for Thumbnail::before_create()
	def thumbnail(w, h, scaling_mode = :fit)
		thumbnails.find(:first, :conditions => [ 'width=? AND height=?', w, h ]) ||
		Thumbnail.create([ :image => self, :width => w, :height => h, :content_type => self.content_type, :product => self.product, :scaling_mode => scaling_mode ]).first
	rescue
		logger.error('Error creating thumbnail tag for image #' + id.to_s)
	end

	def cropped_thumbnail(w, h)
		thumbnails.find(:first, :conditions => [ 'width=? AND height=?', w, h ]) ||
		Thumbnail.create([ :image => self, :width => w, :height => h, :content_type => self.content_type, :product => self.product, :scaling_mode => :croppedin ]).first
	rescue
		logger.error('Error creating thumbnail tag for image #' + id.to_s)
	end
end

# Each product image can have zero or more Thumbnails, which are just like images themselves.

class Thumbnail < Image
	belongs_to :image, :foreign_key => 'thumbnail_of'
	attr_accessor :scaling_mode

	# Does the hard work of creating the thumbnail. There are a bunch of scaling modes available:
	# * +crop+ - scales the image so that as much as possible of the picture is in the thumbnail, and crops out everything else.
	# * +stretch+ - stretches the image (non-proportionally) to fit the thumbnail
	# * +fit+ - scales the image proportionally to fit the frame, filling any excess with white
	def before_create
		img = GD2::Image::load(self.image.data)
		img2 = GD2::Image::TrueColor.new(self.width, self.height)

		img2.draw do |canvas|
			canvas.color = GD2::Color::WHITE
			canvas.rectangle 0, 0, self.width, self.height, true
		end

		case (scaling_mode || :crop)
		when :crop
			sh = self.height.to_f / img.height.to_f
			sw = self.width.to_f / img.width.to_f
			if sw > sh
				y = self.height * img.width / self.width
				img2.copy_from(img, 0, 0, 0, 0, self.width, self.height, img.width, y)
			else
				x = self.width * img.height / self.height
				img2.copy_from(img, 0, 0, 0, 0, self.width, self.height, x, img.height)
			end
		when :croppedin
			# this crops in about 15% from each side
			img2.copy_from(img, 0, 0, (img.width * 0.15).round, (img.height * 0.15).round, self.width, self.height, (img.width * 0.7).round, (img.height * 0.7).round)
		when :stretch
			img2.copy_from(img, 0, 0, 0, 0, self.width, self.height, img.width, img.height)
		when :fit
			s = [self.height.to_f / img.height.to_f, self.width.to_f / img.width.to_f].min
			w = img.width * s
			h = img.height * s
			x = (self.width - w) / 2
			y = (self.height - h) / 2
			img2.copy_from(img, x, y, 0, 0, w, h, img.width, img.height)
		end
		self.data = img2.jpeg(80)

		self.content_type = 'image/jpeg'
		self.filename = "#{self.width}x#{self.height}-" + self.image.filename
		self.caption = self.image.caption
	rescue
		logger.error('Error creating thumbnail image for image #' + id.to_s)
	end
end
