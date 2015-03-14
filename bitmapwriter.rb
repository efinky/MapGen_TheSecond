# coding: binary
 
class BMP
	class Writer
		PIXEL_ARRAY_OFFSET = 54
		BITS_PER_PIXEL = 24
		DIB_HEADER_SIZE = 40
		PIXELS_PER_METER = 2835 # 2835 pixels per meter is basically 72dpi
		 
		def initialize(width, height)
			@width, @height = width, height
			 
			@pixels = Array.new(@height) { Array.new(@width) { "000000" } }
		end
		 
		def [](x,y)
			@pixels[y][x]
		end
		 
		def []=(x,y,value)
			@pixels[y][x] = value
		end
		 
		def save_as(filename)
			File.open(filename, "wb") do |file|
				write_bmp_file_header(file)
				write_dib_header(file)
				write_pixel_array(file)
			end
		end
	 
		private
		 
		def write_bmp_file_header(file)
			file << ["BM", file_size, 0, 0, PIXEL_ARRAY_OFFSET].pack("A2Vv2V")
		end
		 
		def file_size
			PIXEL_ARRAY_OFFSET + pixel_array_size
		end
		 
		def pixel_array_size
			((BITS_PER_PIXEL*@width)/32.0).ceil*4*@height
		end
		
		def write_dib_header(file)
			file << [DIB_HEADER_SIZE, @width, @height, 1, BITS_PER_PIXEL,
			0, pixel_array_size, PIXELS_PER_METER, PIXELS_PER_METER,
			0, 0].pack("Vl<2v2V2l<2V2")
		end
		 
		def write_pixel_array(file)
			@pixels.reverse_each do |row|
				row.each do |color|
					file << pixel_binstring(color)
				end
				 
				file << row_padding
			end
		end
	 
		def pixel_binstring(rgb_string)
			raise ArgumentError unless rgb_string =~ /\A\h{6}\z/
			[rgb_string].pack("H6")
		end
		 
		def row_padding
		"\x0" * (@width % 4)
		end
	end
end