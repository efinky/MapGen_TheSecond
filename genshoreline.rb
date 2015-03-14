require 'rubygems'
require 'gosu'
include Math

class GenShoreline
	attr_reader :map
	def initialize(length, rnum, map)
		@length = length
		@rand = rnum
		@map = map
		
		#defines a rectangular section
		@section_struct = Struct.new :x1, :y1, :x2, :y2
		@point_struct = Struct.new :x, :y
		
		@sections = Array.new
		@points = Array.new
			
		
		createSections
		createPoints
		connectPoints
		
		
		
		#puts "painting sections"
		#paintSection
		
		
	end
	def paintSection
		@sections.each do |section|
			x1 = section.x1
			y1 = section.y1
			x2 = section.x2
			y2 = section.y2
			while x1 != x2
				@map[x1][y1].elevation = 0
				@map[x1][y2].elevation = 0
				x1+= x1 > x2 ? -1 : 1
			end
			x1 = section.x1
			y1 = section.y1
			x2 = section.x2
			y2 = section.y2
			while y1 != y2
				@map[x1][y1].elevation = 0
				@map[x2][y1].elevation = 0
				y1+=y1 > y2 ? -1 : 1
			end
			
		end
	end
	
	def createSections
		#d = 30
		
		#pick a certain number of points per line, can be random between two values
		#numPoints = rand(8..10)
		#loop through numPoints times create section
		
		#calculate length of section
		numPoints = @rand.rand(8..10)
		d = (@length/numPoints).to_i
		buffer = (d/4).to_i
		offset = 20
		#length = ((@length)/d).to_i
		
		x = 0 + offset
		y = 0 + offset
		newx = x + d 
		newy = y + d
		#nw->ne
		#@sections.push(@section_struct.new x, y, newx, newy)
		#for i in (1..numPoints)
		while (newx + d + buffer <= @length - offset - 1)
				x = newx + buffer
				newx += d + buffer
				#this is how I would randomize boxes
				#ty = newy + rand(-(d/4).to_i..d)
				@sections.push(@section_struct.new x, y, newx, newy)	
		end
		@sections.pop
		
		x = @length - 1 - d - offset
		y = d + offset + buffer
		newx = x + d
		newy = y + d
		#ne->se
		#@sections.push(@section_struct.new x, y, newx, newy)	
		#for i in (2..numPoints)
		while (newy + d + buffer <= @length - offset - 1)			
				y = newy + buffer
				newy += d + buffer
				@sections.push(@section_struct.new x, y, newx, newy)		
			#end
		end
		@sections.pop
		
		x = @length - 1 - (d*2) - offset - buffer
		y = @length - 1 - d - offset
		newx = x + d
		newy = y + d
		#se->sw
		#@sections.push(@section_struct.new x, y, newx, newy)
		#how do I reverse a range?
		#for i in (numPoints-2).downto(0)
		while (x - d - buffer >= offset) and
				newx = x - buffer
				x -= (d + buffer)
				@sections.push(@section_struct.new x, y, newx, newy)		
		end
		@sections.pop
		
		x = 0 + offset
		y = @length - 1 - (d*2) - offset - buffer
		newx = x + d
		newy = y + d
		#sw->nw
		#@sections.push(@section_struct.new x, y, newx, newy)
		#puts length
		while (y - (d + buffer)  >= offset + (@sections.first.y2 - @sections.first.y1))
				newy = y - buffer
				y -= (d + buffer)
				@sections.push(@section_struct.new x, y, newx, newy)
		end
	
	end
	def createPoints
		count = @rand.rand(2)
		@sections.each do |section|
			if count % 2 == 0
				point = @point_struct.new section.x1 > section.x2 ? @rand.rand(section.x2..section.x1) : @rand.rand(section.x1..section.x2),
					section.y1 > section.y2 ? @rand.rand(section.y2..section.y1) : @rand.rand(section.y1..section.y2)
				@points.push(point)
			end
			count += 1
		end		
	end
	def connectPoints
		i = 1
		prev = @points[0]
		while i < @points.length
			gen_edge(prev.x, prev.y, @points[i].x, @points[i].y)
			
			prev = @points[i]
			i+=1
		end
		gen_edge(@points.last.x, @points.last.y, @points.first.x, @points.first.y)
	end
	def gen_edge(x1, y1, x2, y2, tile_name = 0)
		exit = false
		x = x1
		y = y1
		initial_angle = find_center_angle(x, y, x2, y2)
		angle = initial_angle
		x, y = map_section_edge(x,y,angle, tile_name)
		distance = find_distance(x,y,x2,y2, initial_angle)
		width = find_width(x,y,x1,y1,x2,y2)
		while distance > 0 and !exit
			#puts "distance = " + distance.to_s
			if distance >= 10
				angle = find_angle_section(angle, initial_angle, 1)
			elsif distance >= 5
				angle = find_angle_section(angle, initial_angle, 1)
			else
				angle = find_center_angle(x, y, x2, y2)
				#tile_name = 5
			end
			x, y = map_section_edge(x,y,angle,tile_name)
			
			#distance = find_distance(x,y,x2,y2,initial_angle)
			#width = find_width(x,y,x1,y1,x2,y2)
			
			if width >= distance
				#increment by an extra one towards the end points
				new_angle = find_center_angle(x, y, x2, y2)
				angle = find_angle_section(angle, initial_angle, 2, new_angle, true)
				x, y = map_section_edge(x,y,angle, tile_name)
				exit = true
			end
			distance = find_distance(x,y,x2,y2,initial_angle)
			width = find_width(x,y,x1,y1,x2,y2)
			
		end
		
		width = find_distance(x, y, x2, y2)
		angle = find_center_angle(x, y, x2, y2)
		while width > 0 and !exit
			x, y = map_section_edge(x,y,angle,tile_name)
			width = find_distance(x, y, x2, y2)
		end
		if !exit
			x, y = map_section_edge(x2,y2,angle,tile_name)
		else
			gen_edge(x, y, x2, y2, tile_name)
		end
		
	end
	
	def map_section_edge(x, y, angle, tile_name)
		@map[check_xy(x)][check_xy(y)].elevation = tile_name
		@map[check_xy(x)][check_xy(y)].type = "ShoreLine"
		#@nodes.push(@point_struct.new x, y)
		x, y = update_x_y(x,y,angle)
		return x, y
	end
	
	def check_xy(xy_value)
		if xy_value >= @length
			xy_value = xy_value - @length
		elsif xy_value < 0
			xy_value = xy_value + (@length)
		end
		return xy_value
	end
	
	def update_x_y(x, y, angle)
		if angle == 2
			x+=1
			y-=1
		elsif angle == 4
			x+=1
			y+=1
		elsif angle == 6
			x-=1
			y+=1
		elsif angle == 8
			x-=1
			y-=1
		elsif angle == 1
			y-=1
		elsif angle == 3
			x+=1
		elsif angle == 5
			y+=1
		elsif angle == 7
			x-=1
		end
		
		return x, y
	end
	
	
	def find_center_angle(x1, y1, x2, y2)
		x = x1
		y = y1 - Math.sqrt((x2 - x1).abs * (x2 - x1).abs + (y2 - y1).abs * (y2 - y1).abs)
		angle = (2 * Math.atan2(y2 - y, x2 - x)) * 180 / PI
		angle = ((angle+22.5)/45 + 1).to_i
		if angle > 8
			angle = 1
		elsif angle < 1
			angle = 8
		end
		return angle
	end
	
	def find_angle_section(angle, center, variance = 2, new_center = 0, increment = false)
		
		#start to come towards point
		if increment == false
			#converts center to array point (from 0..7 instead of 1..8)
			center -= 1
			angles_list = [(center - 2)%8+1, (center - 1)%8+1, center%8+1, (center + 1)%8+1, (center + 2)%8+1]
			
			index = angles_list.index(angle)
			
			#keep accidents from crashing the program
			if index == nil
				index = 2
			end
			#change by one degree either way, or stay same direction
			turn = @rand.rand(-1..1)
			index += turn
			if variance == 2
				if index < 0
					index = 1
				elsif index > 4
					index = 3
				end
			else
				if index < 1
					index = 1
				elsif index > 3
					index = 3
				end		
			end
			return_angle = angles_list[index]
		else			
			if angle > new_center
				angle -= 1
			elsif angle < new_center
				angle += 1
			end
			if angle > 8
				angle = 1
			elsif angle < 1
				angle = 8
			end
			
			return_angle = angle
			
		end
		return return_angle
	end
	def find_width(x, y, x1, y1, x2, y2)
		#width from center line
		if x2-x1 != 0
			m = (y2-y1)/(x2-x1)
			b = y2 - m*x2
			width = (y-(m*x)-b).abs/(Math.sqrt(m**2 + 1))
		else
			width = (x2 - x).abs
		end		
		return width
		
	end
	def find_distance(x, y, x2, y2, initial_angle = 0)

		#find distance based on angle
		if initial_angle != 0
			cross_angle = ((initial_angle-1) + 2)%8+1
			x1,y1 = update_x_y(x2, y2, cross_angle)
			if x2-x1 != 0
				m = (y2-y1)/(x2-x1)
				b = y2 - m*x2
				distance = (y-(m*x)-b).abs/(Math.sqrt(m**2 + 1))
			else
				distance = (x2 - x).abs
			end
		#simple find distance
		else
			if x == x2
				distance = (y-y2).abs
			elsif y == y2
				distance = (x-x2).abs
			else
				distance = Math.sqrt((x2 - x).abs * (x2 - x).abs + (y2 - y).abs * (y2 - y).abs)
			end
		end
		return distance
	end
end