#also in future manage different tile sizes?
require 'rubygems'
require 'gosu'
require './genshoreline'
require './genmountain'
require './genregions'
require './bitmapwriter'

require './genocean'
#require './genriver'
include Math

#lakes and mountains happen first, then roads, then trees?

class MapGen
	attr_reader :bitmap_name
	def initialize (window, width, height, rows)
		@window = window
		@width = width
		@height = height
		@rows = rows
		
		@map_struct = Struct.new :elevation, :type
		puts "initializing array..."
		@map = Array.new(@rows) { Array.new(@rows) { @map_struct.new -1, nil } }
		@tile_size = 10 #91312#48482#
		seed = rand(99999)
		@bitmap_name = seed
		puts "seed = " + seed.to_s
		@rand = Random.new(seed)
		
		
		puts "generating shoreline..."
		shore = GenShoreline.new(@rows, @rand, @map)
		
		
		puts "generating ocean"
		ocean = GenOcean.new(@map, @rows)
		
		#puts Time.now.to_i
		puts "generating regions..."
		regions = GenRegions.new(@rows, @rand, seed, @map, (@rows/10).to_i)
		#puts Time.now.to_i
		puts "smoothing noise..."
		smoothMap
		#puts Time.now.to_i
		puts "generating mountains..."
		
		mons = GenMountain.new(@rows, @rand,seed, @map)
		
		
		
		#puts "generating rivers..."
		#points = mons.points
		#river = GenRiver.new(@rows, @map, @rand)
		#for point in points
			#point = points[0]
			#point.x += (@rand.rand(10) - 5)
			#point.y += (@rand.rand(10) - 5)
			#river.start(point)
			#point = points[1]
			#point.x += (@rand.rand(10) - 5)
			#point.y += (@rand.rand(10) - 5)
			#river.start(point)
		#end
		#puts Time.now.to_i
		
		puts "saving file"
		saveFile(seed)
		
		puts "creating bitmap"
		saveBinary(seed)
		
		puts "Done..."
		
		
		
		# elevations = water, sand, grasslands, higherplanes, hills, 
		# rocky terrain, cliffs, peaks, (or something like that)
		#deep blue, light blue, sand, light green, green, darker green,
		#grey, light grey, white
		
		# need two different kinds of maps, maps for storing information 
		# for displaying and map that stores information for generating
		
		# for displaying purposes all we need to know is elevation
		# tile_struct = Struct.new :elevation, 
		# for generating purposes, it will depend on what we are generating
		# for generating the shoreline we need to know, a list of points
			#for list of points, cut edges of map into quadrants, randomly
			#generate depth of quadrant (and to some degree width?) 
			#then pick a random point inside of quadrant
			#proceed to next quadrant and repeat
		# and then use our crazy pathing for river to connect them all
		
		# for filling in ocean we need to use a regular fill method
		
		# ocean will then be apart of all other maps
		
		# 
		
		
	end
	def saveBinary(seed)
		bmp = BMP::Writer.new(@rows, @rows)
		for i in (0..@rows-1)
			for j in (0..@rows-1)
				if @map[i][j].type == "Ocean"
					bmp[i,j] = "ff0000"
				elsif @map[i][j].type == "River"
					bmp[i,j] = "ff0000"
				elsif @map[i][j].type == "Lake"
					bmp[i,j] = "ff0000"
				elsif @map[i][j].elevation == 10
					bmp[i,j] = "ffffff"
				elsif @map[i][j].elevation == 9
					bmp[i,j] = "d0d0d0"
				elsif @map[i][j].elevation == 8
					bmp[i,j] = "b0b0b0"
				elsif @map[i][j].elevation == 7
					bmp[i,j] = "808080"
				elsif @map[i][j].elevation == 6
					bmp[i,j] = "005500"
				elsif @map[i][j].elevation == 5
					bmp[i,j] = "007700"
				elsif @map[i][j].elevation == 4
					bmp[i,j] = "009900"
				elsif @map[i][j].elevation == 3
					bmp[i,j] = "00bb00"
				elsif @map[i][j].elevation == 2
					bmp[i,j] = "00dd00"
				elsif @map[i][j].elevation == 1
					bmp[i,j] = "00ee00"
				elsif @map[i][j].elevation == 0
					bmp[i,j] = "00ff00"
				else
					bmp[i,j] = "000000"
				end
			end
		end
		@bitmap_name = "map_" + seed.to_s + ".bmp"
		bmp.save_as(@bitmap_name)
		
	end
	
	def saveFile(seed)
		fileName = "map_" + seed.to_s + ".tbm"
		file = File.open(fileName, "w")
		
		str = @width.to_s + ", " + @height.to_s + "\n"
		file.write(str)
		for i in (0..@rows-1)
			str = ""
			for j in (0..@rows-1)
				if @map[i][j].type == "Ocean"
					str += "-1,"
				elsif @map[i][j].type == "ShoreLine"
					str += "-2,"
				else
					str += @map[i][j].elevation.to_s + ","
				end
			end
			str += "\n"
			file.write(str)
		end
		file.close
		
	end
	def getSurroundingNodesElevation(x, y)
		temp_a = Array.new
		for i in (x-1..x+1)
			for j in (y-1..y+1)
				if (i >= 0 and j >= 0 and i < @rows and j < @rows)
					if (@map[i][j].elevation != -1)
						temp_a.push(@map[i][j])
					end
				end
			end
		end
		return temp_a
	end 
	def smoothMap
		for i in (0..@rows-1)
			for j in (0..@rows-1)
				temp_a = getSurroundingNodesElevation(i, j)
				temp = 0.0
				if temp_a.count != 0
					for n in temp_a
						temp += n.elevation
					end
					temp = temp/temp_a.count
					#temp += 0.5
				else
					temp = -1
				end
				@map[i][j].elevation = temp.to_i
			end
		end
	end
	def draw
		(0..@rows-1).each do |r|
			(0..@rows-1).each do |c|
				x = r
				y = c
				if @map[r][c].type == "Ocean"
					color = Gosu::Color.argb(0xff0000ff)
				elsif @map[r][c].type == "River"
					color = Gosu::Color.argb(0xffffa500)
				elsif @map[r][c].type == "Lake"
					color = Gosu::Color.argb(0xffff00ff)
				elsif @map[r][c].type == "ShoreLine"
					color = Gosu::Color.argb(0xffffff00)
				elsif @map[r][c].elevation == 10
					color = Gosu::Color.argb(0xffffffff)
				elsif @map[r][c].elevation == 9
					color = Gosu::Color.argb(0xffd0d0d0)
				elsif @map[r][c].elevation == 8
					color = Gosu::Color.argb(0xffb0b0b0)
				elsif @map[r][c].elevation == 7
					color = Gosu::Color.argb(0xff808080)
				elsif @map[r][c].elevation == 6
					color = Gosu::Color.argb(0xff005500)
				elsif @map[r][c].elevation == 5
					color = Gosu::Color.argb(0xff007700)
				elsif @map[r][c].elevation == 4
					color = Gosu::Color.argb(0xff009900)
				elsif @map[r][c].elevation == 3
					color = Gosu::Color.argb(0xff00bb00)
				elsif @map[r][c].elevation == 2
					color = Gosu::Color.argb(0xff00dd00)
				elsif @map[r][c].elevation == 1
					color = Gosu::Color.argb(0xff00ee00)
				elsif @map[r][c].elevation == 0
					color = Gosu::Color.argb(0xff00ff00)
				else
					color = Gosu::Color.argb(0x00000000)#0xff00ff00)
					#puts @map[r][c].elevation
				end
				@window.draw_quad(x*@tile_size, y*@tile_size, color, x*@tile_size + @tile_size, y*@tile_size, color, x*@tile_size, y*@tile_size + @tile_size, color, x*@tile_size + @tile_size, y*@tile_size + @tile_size, color) 
			end
		end
	end
	def draws(c_x, c_y)
		x_edge = @width/2
		y_edge = @height/2
		x = 1
		y = 1
	
		(c_x - x_edge..x_edge + c_x).each do |r|
			(c_y - y_edge..y_edge + c_y).each do |c|
				if r >= @rows
					r = r-@rows
				end
				if r < 0
					r = r+@rows
				end
				if c >=@rows
					c = c-@rows
				end
				if c < 0
					c = c+@rows
				end
				if @map[r][c].type == "Ocean"
					color = Gosu::Color.argb(0xff0000ff)
				elsif @map[r][c].elevation == 10
					color = Gosu::Color.argb(0xffffffff)
				elsif @map[r][c].elevation == 9
					color = Gosu::Color.argb(0xffd0d0d0)
				elsif @map[r][c].elevation == 8
					color = Gosu::Color.argb(0xffb0b0b0)
				elsif @map[r][c].elevation == 7
					color = Gosu::Color.argb(0xff808080)
				elsif @map[r][c].elevation == 6
					color = Gosu::Color.argb(0xff005500)
				elsif @map[r][c].elevation == 5
					color = Gosu::Color.argb(0xff007700)
				elsif @map[r][c].elevation == 4
					color = Gosu::Color.argb(0xff009900)
				elsif @map[r][c].elevation == 3
					color = Gosu::Color.argb(0xff00bb00)
				elsif @map[r][c].elevation == 2
					color = Gosu::Color.argb(0xff00dd00)
				elsif @map[r][c].elevation == 1
					color = Gosu::Color.argb(0xff00ee00)
				elsif @map[r][c].elevation == 0
					color = Gosu::Color.argb(0xff00ff00)
				else
					color = Gosu::Color.argb(0x00000000)
				end
				@window.draw_quad(x*@tile_size, y*@tile_size, color, x*@tile_size + @tile_size, y*@tile_size, color, x*@tile_size, y*@tile_size + @tile_size, color, x*@tile_size + @tile_size, y*@tile_size + @tile_size, color) 
				y+=1
			end
			x+=1
			y=1
		end
	end
end