require 'spreadsheet/excel'
include Spreadsheet

# Generic class for writing Excel-format reports.
# For more information, see http://rubyspreadsheet.sourceforge.net/

class Report
	attr_reader :worksheet

	def initialize(filename)
		@filename = filename

		@workbook = Excel.new(filename)
		@worksheet = @workbook.add_worksheet

		@formats = {}
		default_font = { :font => 'Tahoma', :size => 8 }
		add_format(:default, default_font)
		add_format(:heading, default_font.merge({ :bold => true, :color => 'white', :bg_color => 'black' }))
		add_format(:price, default_font.merge({ :num_format => '$#,##0.00' }))
		add_format(:date, default_font.merge({ :num_format => 'dd/mm/yyyy' }))
		add_format(:title, default_font.merge({ :bold => true, :color => 'white', :bg_color => 'black', :size => 16 }))

		@worksheet.format_row(0, 30, @formats[:title])
		@worksheet.format_row(1, nil, @formats[:heading])

		@format = @workbook.add_format({})
		@worksheet.write(0, 0, '')
	end

	# Adds a format to the workbook.
	def add_format(name, values)
		@formats[name.to_sym] = @workbook.add_format(values)
	end

	# Writes a value or values to the workbook at the given location, using the given format.
	# +value+ can either be a single value, or an array of values, which can either
	# be given as scalars, or as +[value, format]+ pairs.
	def write(row, column, value, format = :default)
		if value.is_a? Array
			value.each do |v|
				if v.is_a? Array
					val = case v[1]
					when :date then (v[0].to_date - Date.civil(1900, 1, 1)) + 2
					else v[0]
					end
					@worksheet.write(row, column, val, @formats[v[1]])
				else
					@worksheet.write(row, column, v, @formats[format])
				end
				column += 1
			end
		else
			@worksheet.write(row, column, value, @formats[format])
		end
	end

	# Writes some rows of data to the spreadsheet.
	def write_rows(data, row = 2, column = 0)
		data.each do |d|
			write(row, column, d)
			row += 1
		end
	end

	# Closes the workbook (important!).
	def close
		@workbook.close rescue nil
		FileUtils.chmod 0666, @filename
	end
end