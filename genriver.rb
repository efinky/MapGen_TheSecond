
class GenRiver
	def initialize(length, map, rand)
		@length = length
		@map = map
		@rand = rand
		@river_struct = Struct.new :parent, :x, :y, :angle, :ttd
		@lake_struct = Struct.new :overflow, :x, :y
		@open = Array.new
		@end = nil
		
	end
	
	def start(point)
		@open.clear
		@end = nil
		node = @river_struct.new nil, point.x, point.y, -1, 200
		#loop here, gen river - iff not ocean or timer has not run out
		#then fill lake
		#if lake overflows
		#gen river again and repeat process
		result = gen_river(node)
		while result != nil
			overflow, node = fillLake(result) # node = @river_struct.new result, temp.x, temp.y, angle, result.ttd
			if overflow == true
				result = gen_river(node)
			end
		end
		#gen_river returns nil if it has hit lake ocean or river or ttd has run out
		#else it returns the point at which to start filling the lake
	end
	
	def gen_river_old(node)
		searchSurroundingNodes(node)
		
		next_node = nil
		begin
			next_node = searchOpenList
			if next_node != nil
				@open.delete(next_node)
				
				searchSurroundingNodes(next_node)
			end
		end while next_node != nil and @end == nil
		#puts next_node
		if @end != nil
			current = @end
			puts "here"
		else
			current = next_node
			puts "there"
		end
		while current.parent != nil
			current = current.parent
			@map[current.x][current.y].type = "River"
			#eventually add in something to make sure its a smooth transition
	
		end
	
	end
	def gen_river(parent)
		@map[parent.x][parent.y].type = "River"
		puts "gen1"
		#getSurroundingLowestElevation now returns a list
		temp_list = getSurroundingLowestElevations(parent)
		
		if temp_list.count == 0
			#stop right here, clearly this isn't going anywhere any time soon
			node = nil
			puts "0"
		elsif temp_list.count == 1
			node = temp_list[0]
			puts node
			puts "1"
		else
			r = @rand.rand(temp_list.count)
			node = temp_list[r]
			puts "random"
		end
		#make sure min <= parent.elevation
		#still have to figure out how/when to end river gen
		#next_node = nil
		i = 0
		exit = false
		while node != nil and @map[node.x][node.y].elevation <= @map[parent.x][parent.y].elevation and node.ttd > 0 and !exit
			parent = node
			@map[parent.x][parent.y].type = "River"
			
			temp_list = getSurroundingLowestElevations(parent)
			if temp_list.count == 0
				exit = true
			elsif temp_list.count == 1
				node = temp_list[0]
			else
				r = @rand.rand(temp_list.count)
				node = temp_list[r]
			end 
			i+=1
		end 
		#puts node
		#puts (@map[node.x][node.y].elevation <= @map[parent.x][parent.y].elevation)
		#puts node.ttd
		#puts exit
		if node.ttd <= 0
			puts "ttd"
			return nil
		else
			return node
		end
	end
	
	def fillLake(parent)
		puts "here"
		#node = @river_struct.new @map[point.x][point.y], point.x, point.y
		searchSurroundingNodes(parent)
		#when overflow figure out angle of river.
		#list of possible overflow points
		overflow_list = Array.new
		river_list = Array.new
		overflow = false
		#new_point = nil
		while @open.count != 0
			node = @open.pop
			#if its a point of overflow
			if node.overflow === true
				#we'll deal with these later
				overflow_list.push(node)
			elsif @map[node.x][node.y].type == "Land"
				@map[node.x][node.y].type = "Lake"
				searchSurroundingNodes(node)
			end
		end
		while overflow_list.count != 0
			node = overflow_list.pop
			angle = find_overflow_angle(node)
			if angle == -1
				if @map[node.x][node.y].type == "Land"
					@map[node.x][node.y].type = "Lake"
				end
			else
				overflow = true
				x, y = update_x_y(node.x, node.y, angle)
				river_list.push @river_struct.new parent, x, y, angle, parent.ttd
			end
		end
		
		
		#overflow angle regardless of what angle is return set that space
		#as Lake - then if angle is not -1 return overflow = true, 
		#and the river_struct node of the tile next to the lake tile just created
		
		#return if overflow, and @river_struct parent, x, y, angle, ttd
		
		#if overflow is false, river_list.pop should return nil
		#else it should return a place to start a new river
		return overflow, river_list.pop
		
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
	#used to return what angle the new river should start at from the lake
	#should only go up down left or right
	def find_overflow_angle(node)
		x = node.x
		y = node.y
		count = 0
		open_tiles = Array.new
		angle = -1
		for i in (x-1..x+1)
			for j in (y-1..y+1)
				#if its not the original node
				if (i != x or j != y)
					#tally up how many lake tiles are nearby us
					if @map[i][j].type == "Lake"
						count+=1
					elsif @map[i][j].elevation <= @map[node.x][node.y].elevation and @map[i][j].type == "Land"
						open_tiles.push(@lake_struct.new true, i, j)
					end
				end
			end
		end
		#as long as we aren't surrounded by more than 5 river tiles
		if open_tiles.count > 0 #and count <= 4
			angle = find_angle(node, open_tiles[0].x, open_tiles[0].y)
		end
		#search surrounding nodes find out on what sides the river is
		#if its on all sides then angle = -1
		#if its on 7 sides then angle = -1
		#if its 5 sides or greater then angle = -1
		#if its on 4 sides or less then angle is dependent on what sides
		#the lake is on
		
		#find a direction that will not lead us next to the lake and is lower
		#elevation if such a direction cannot be found return -1
		
		return angle
	end
	def checkNode(x, y, e)
		if (x >= 0 and y >= 0 and x < @length and y < @length)
			#if the elevation of this node is the same as the level we are filling in, or if its less than
			#then we will fill it
			if @map[x][y].elevation == e and @map[x][y].type == "Land"
				node = @lake_struct.new false, x, y
				if !(isInOpen(node))
					@open.push(node)
				end
			elsif @map[x][y].elevation < e and @map[x][y].type == "Land"
				node = @lake_struct.new true, x, y
				if !(isInOpen(node))
					@open.push(node)
				end
			end
		end
	end
	def isInOpen(node)
		for n in @open
			if n.x == node.x and n.y == node.y
				return true
			end
		end
		return false
	end
	def searchSurroundingNodes(node)
		x = node.x
		y = node.y
		elevation = @map[x][y].elevation
		checkNode(check_xy(x-1), check_xy(y), elevation)
		checkNode(check_xy(x+1), check_xy(y), elevation)
		checkNode(check_xy(x), check_xy(y-1), elevation)
		checkNode(check_xy(x), check_xy(y+1), elevation)
	end
	def compareNodes(a, b)
		return (a.x == b.x and a.y == b.y)
	end
	#returns if waterFound and list of nodes with the same lowest elevation
	def getSurroundingLowestElevations(parent)
		x = parent.x
		y = parent.y
		cost = 0
		min = nil
		waterFound = false
		water = nil
		min_list = Array.new
		
		#search nodes around parent node
		for i in (x-1..x+1)
			for j in (y-1..y+1)
				#if its not the parent node
				if (i != x or j != y)
					temp = @map[check_xy(i)][check_xy(j)]
					
					#if we've managed to find the ocean or some other water
					if temp.type != "Land"
						waterFound = true
						water = @river_struct.new parent, check_xy(i), check_xy(j), find_angle(parent, check_xy(i), check_xy(j)), parent.ttd-1
					elsif (temp.elevation != -1 and temp.type == "Land")
						if  min == nil or temp.elevation < @map[min.x][min.y].elevation
							min_list.clear
							min = @river_struct.new parent, check_xy(i), check_xy(j), find_angle(parent, check_xy(i), check_xy(j)), parent.ttd-1
							min_list.push(min)
						elsif temp.elevation == @map[min.x][min.y].elevation
							min_list.push(@river_struct.new parent, check_xy(i), check_xy(j), find_angle(parent, check_xy(i), check_xy(j)), parent.ttd-1)
						end
						
					end
				end
			end
		end
		#if water has been found clear other options and use that node
		if waterFound
			min_list.clear
			min_list.push(water)
		end
		
		return min_list
		
	end
	def find_angle(parent, x2, y2)
		x1 = parent.x
		y1 = parent.y
		
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
	def check_xy(xy_value)
		if xy_value >= @length
			xy_value = xy_value - @length
		elsif xy_value < 0
			xy_value = xy_value + (@length)
		end
		return xy_value
	end
	
end