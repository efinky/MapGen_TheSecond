require 'rubygems'
require './linkedlist'

class GenMountain
	attr_reader :points
	def initialize(length, rnum, seed, map)
		@length = length
		@rand = rnum
		
		#not sure we really need to pass in the map?  though I suppose it
		#would be better to merge the two maps here...
		@map = map
		@open = LinkedList.new()
		@variation = 5
		@dist_of_variation = 20
		@node_struct = Struct.new :elevation, :direction, :cost, :closed, :open, :dist, :x, :y
		@temp_map = Array.new
		@maxElevation = 10
		@minElevation = 1
		@buffer = (@length/7).to_i
		#initialize an empty map full of nodes
		for i in (0..@length-1)
			@temp_map.push(Array.new)
			for j in (0..@length-1)
				@temp_map[i].push(@node_struct.new -1, -1, 0, false, false, -1, i, j)
			end
		end
		@points = Array.new
		@point_struct = Struct.new :x, :y
		
		startGeneration
		
		for i in (0..@length-1)
			for j in (0..@length-1)
				#if we are over land then merge with the current elevation
				if @map[i][j].type != "Ocean"
					if @temp_map[i][j].elevation >= 1
						if @map[i][j].elevation == -1
							@map[i][j].elevation = @temp_map[i][j].elevation
						elsif @map[i][j].elevation > @temp_map[i][j].elevation
							#do nothing
						else
							@map[i][j].elevation = @temp_map[i][j].elevation#(((@temp_map[i][j].elevation*3 + @map[i][j].elevation)/4).to_i) + 1
						end
						@map[i][j].type = "Land"
					end
				#else if we are over the ocean then overwrite any current elevation
				#new attempt, if over ocean reduce elevation ("due to errosion")
				else
					#if @temp_map[i][j].elevation != -1
					#	newElevation = @temp_map[i][j].elevation/2
					#	if newElevation > 0
					#		@map[i][j].elevation = newElevation
					#		@map[i][j].type = "Land"
					#	end
					#end
				end
				
			end
		end
		@temp_map = nil
		
	end
	
	def startGeneration
		#generate random points from which to start generating.
		#number of points should be influenced by @length
		
		#generate points
		numPoints = (@length/500).to_i + 1
		
		numPoints.times do
			x = @rand.rand(@buffer..(@length - @buffer*2))
			y = @rand.rand(@buffer..(@length - @buffer*2))
			@points.push(@point_struct.new x, y)
		end
		
		numRidges = (numPoints/3).to_i + 1
		
		numRidges.times do
			len = @rand.rand((@buffer/2).to_i)
			x = @rand.rand(@buffer..(@length - @buffer*2))
			y = @rand.rand(@buffer..(@length - @buffer*2))
			@points.push(@point_struct.new x, y)
			len.times do
				newx = x + @rand.rand(15) - @rand.rand(7)
				newy = y + @rand.rand(15) - @rand.rand(7)
				if newx >= 0 and newx < @length
					x = newx
				end
				if  newy >= 0 and newy < @length
					y = newy
				end
				@points.push(@point_struct.new x, y)
			end
			
		end
		
		
		
		for point in @points
			x = point.x
			y = point.y
			max = @rand.rand(@maxElevation-1..@maxElevation)
			@temp_map[x][y].elevation = max
			@temp_map[x][y].direction = 0
			@temp_map[x][y].closed = true
			searchSurroundingNodes(@temp_map[x][y])
		end
		
		tempList = @open.asList
		for node in tempList
			@temp_map[node.x][node.y].dist = @rand.rand(@variation)* @dist_of_variation
			#node.dist = @rand.rand(@variation)* 10
			#node.ttd = 0;# rd.Next(60) * 10;
        end
		
		generateOutFromCenter
		
	end
	
	def generateOutFromCenter
		while @open.count != 0
			x, y = @open.popNode
			if x != -1
				next_node = @temp_map[x][y]
				next_node.closed = true
				next_node.open = false
				timeout = false
				if (next_node.dist <= 0)
					timeout = true
				end
				checkCostAndSetElevationAndColor(next_node)
				if !(timeout and next_node.elevation <= @minElevation)
					searchSurroundingNodes(next_node)
				end
			end
		end
	end
	
	#def searchOpenList
	#	min = nil
	#	if (@open.count != 0)
	#		min = @open.first
	#		for n in @open
	#			if (n.cost < min.cost)
	#				min = n
	#			end
	#		end
	#	end
	#	return min;
	#end
	
	def checkCostAndSetElevationAndColor(node)
	
		test = false
		if node.dist <= 0
			test = true
		end
		node = chosenDirection(node)
		node.elevation = chosenElevation(node)
		
		if node.elevation == @minElevation and test
			node.direction = -2
		end
		
		@temp_map[node.x][node.y].elevation = node.elevation
		@temp_map[node.x][node.y].direction = node.direction
	end
	def chosenDirection(node)
		newDirection = 0
		if (node.dist <= 0)
		
			node.dist = @rand.rand(@variation) * @dist_of_variation
			newDirection = @rand.rand(0..1)
			if @rand.rand(0..20)%17 == 0
				newDirection+=1
			end
			
		end
		node.direction = newDirection
		return node
	end
	def chosenElevation(node)
		newElevation = compareSurroundingNodesElevation(
			getSurroundingNodesElevation(node)).elevation
		if node.direction == 1
			if (newElevation > 0)
				newElevation-=1
			end
		elsif node.direction == 2
			if (newElevation < @maxElevation - 1)
				newElevation+=1
			end
		end
		return newElevation
	end
	def compareSurroundingNodesElevation(array)
		while(array.count < 3)
			if array.count <= 1
				array.push(array[0])
			else
				array.push(array[@rand.rand(array.count-1)])
			end
		end
		return array[@rand.rand(array.count-1)]
	end
	def getSurroundingNodesElevation(node)
		x = node.x
		y = node.y
		temp_a = Array.new
		for i in (x-1..x+1)
			for j in (y-1..y+1)
				if (i >= 0 and j >= 0 and i < @length and j < @length)
					if (@temp_map[i][j].elevation != -1)
						temp_a.push(@temp_map[i][j])
					end
				end
			end
		end
		return temp_a
	end 
	def searchSurroundingNodes(parent)
		x = parent.x
		y = parent.y
		cost = 0
		#search nodes around parent node
		for i in (x-1..x+1)
			for j in (y-1..y+1)
				#if its not the parent node
				if (1 != x or j != y)
					if (i==x or j==y)
						#cost for straight
						cost = 10
					else
						#cost for diagonal
						cost = 14
					end
					if (i >= 0 and j >= 0 and i < @length and j < @length)
						current = @temp_map[i][j]
						#ignore node if its already in the closed list
						if !current.closed
							#ignore node if its already in the open list
							if !current.open
								#current.parent = parent
								current.cost = parent.cost+cost
								if parent.direction != -1
									current.direction = parent.direction
								end
								if parent.dist != -1
									current.dist = parent.dist - cost
								end
								#if parent.ttd != -1
								#	current.ttd = parent.ttd
								#end
								
								#if we have reached minElevation and dist/ttd has run out
								#then don't add to open list
								#if current.direction != -2#!(parent.elevation <= @minElevation and parent.dist <= 0)
								current.open = true
								@open.insertNode(current.x, current.y, current.cost)
								#end
								
							end
						end
					
					end
				end
			end
		end
	end
	
	def smoothMap
		for i in (0..@length-1)
			for j in (0..@length-1)
				temp_a = getSurroundingNodesElevation(@temp_map[i][j])
				temp = 0.0
				if temp_a.count != 0
					for n in temp_a
						temp += n.elevation
					end
					temp = temp/temp_a.count
					temp += 0.5
				else
					temp = -1
				end
				@temp_map[i][j].elevation = temp.to_i
			end
		end
	end
	
end