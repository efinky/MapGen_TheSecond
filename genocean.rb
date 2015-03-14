require 'rubygems'
require 'gosu'

class GenOcean
	attr_reader :map
	def initialize(map, length)
		@length = length
		@map = map
		@open = Array.new
		@temp_map = Array.new
		#code for filling in ocean
		@node_struct = Struct.new :elevation, :type, :x, :y, :closed, :open
		for i in (0..@length-1)
			@temp_map.push(Array.new)
			for j in (0..@length-1)
				@temp_map[i].push(@node_struct.new @map[i][j].elevation, @map[i][j].type, i, j, false, false)
				if @temp_map[i][j].elevation != -1
					@temp_map[i][j].closed = true
				end
			end
		end
		fillOcean
		
		for i in (0..@length-1)
			for j in (0..@length-1)
				@map[i][j].elevation = @temp_map[i][j].elevation
				@map[i][j].type =  @temp_map[i][j].type
			end
		end
		@temp_map = nil
	end

	def fillOcean
		#start at each corner
		start_nodes = Array.new
		start_nodes.push(@temp_map[0][0])
		#start_nodes.push(@temp_map[0][@length-1])
		#start_nodes.push(@temp_map[@length-1][0])
		#start_nodes.push(@temp_map[@length-1][@length-1])

		
		#populate open list with nodes surrounding start_nodes
		start_nodes.each do |node|
			@temp_map[node.x][node.y].closed = true
			@temp_map[node.x][node.y].elevation = 0
			@temp_map[node.x][node.y].type = "Ocean"
			searchSurroundingNodes(@temp_map[node.x][node.y])
		end
		
		#searchSurroundingNodes populates open list
		#next_node = @open.first
		#show = 0
		while @open.count != 0
			next_node = @open.pop
			if next_node.elevation != nil
				@temp_map[next_node.x][next_node.y].closed = true
				@temp_map[next_node.x][next_node.y].elevation = 0
				@temp_map[next_node.x][next_node.y].type = "Ocean"
				@temp_map[next_node.x][next_node.y].open = false
				#@open.pop
			end
			#if show%10 == 0
				#puts "show " + show.to_s
				#puts "open " + @open.count.to_s
			#end
			searchSurroundingNodes(@temp_map[next_node.x][next_node.y])
			#show+=1
		end
		
	end
	
	def searchSurroundingNodes(node)
		x = node.x
		y = node.y
		
		checkNode(check_xy(x-1), check_xy(y))
		checkNode(check_xy(x+1), check_xy(y))
		checkNode(check_xy(x), check_xy(y-1))
		checkNode(check_xy(x), check_xy(y+1))
		
		
	end
	def checkNode(x, y)
		if (x >= 0 and y >= 0 and x < @length and y < @length)
			if !@temp_map[x][y].closed
				if(!(@temp_map[x][y].open))
					@temp_map[x][y].open = true
					@open.push(@temp_map[x][y])
				end
			end
		end
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