require 'rubygems'
require 'perlin'
require './linkedlist'

class GenRegions
	attr_reader :map
	def initialize(length, rnum, seed, map, numRegions)
		@length = length
		@rand = rnum
		@seed = seed
		#not sure we really need to pass in the map?  though I suppose it
		#would be better to merge the two maps here... persistence
		@map = map
		@open = LinkedList.new()
		@variation = 10
		@node_struct = Struct.new :addNoise, :elevation, :direction, :persistence, :cost, :closed, :open, :dist, :x, :y
		@temp_map = Array.new
		@buffer = (@length/7).to_i
		@numRegions = numRegions
		@maxElevation = 0
		@persistence = 0
		#initialize an empty map full of nodes
		for i in (0..@length-1)
			@temp_map.push(Array.new)
			for j in (0..@length-1)
				@temp_map[i].push(@node_struct.new false, -1, -1, -1, 0, false, false, -1, i, j)
			end
		end
		
		#generate regions
		
		#use the regions to generate "noisy" terrain
		numRegions.times do
			genRegion(@rand.rand(10), @rand.rand(7))
			addNoise(@rand.rand(2) == 1 ? 0.25 : 0.5, @rand.rand(20) + 1)			
		end
		puts "adding noise..."
		#fill in anything else with low noise
		gen = Perlin::Generator.new @seed, 0.5, 12
		for i in (0..@length-1)
			for j in (0..@length-1)
				if @temp_map[i][j].elevation == -1
					@temp_map[i][j].elevation = ((gen[i, j]).abs*10).to_i
				end
			end
		end
		
		for i in (0..@length-1)
			for j in (0..@length-1)
				if @map[i][j].elevation == -1
					if @temp_map[i][j].elevation != -1
						@map[i][j].elevation = @temp_map[i][j].elevation
						@map[i][j].type = "Land"
					end
				end
			end
		end
		@temp_map = nil
		
	end
	
	def addNoise(persistence, octaves)
		gen = Perlin::Generator.new @seed, persistence, octaves
		for i in (0..@length-1)
			for j in (0..@length-1)
				if @temp_map[i][j].addNoise == true
					@temp_map[i][j].elevation = ((gen[i, j]).abs*10).to_i+@temp_map[i][j].elevation
					if @temp_map[i][j].elevation > 10
						@temp_map[i][j].elevation = 10
					end
					@temp_map[i][j].addNoise = false
				end
			end
		end
	end
	
	def genRegion(elevation, persistence)
		@maxElevation = elevation
		@persistence = persistence
		v = 10 #(@numRegions/2).to_i
		@variation = @rand.rand(v) + v
		startGeneration
		
	end
	
	def startGeneration
		#generate random points from which to start generating.
		#number of points should be influenced by @length
		
		#generate a few points near each other to simulate a mountain ridge
		#x = 0
		#y = 0
		#while (@temp_map[x][y].elevation != -1)
		x = @rand.rand(@buffer..(@length - @buffer*2))
		y = @rand.rand(@buffer..(@length - @buffer*2))
		#if we aren't on the mainland try again with tighter constraints
		if (@temp_map[x][y].elevation == -1)
			x = @rand.rand(@buffer*2..(@length - @buffer*4))
			y = @rand.rand(@buffer*2..(@length - @buffer*4))
		end
		@temp_map[x][y].elevation = @maxElevation
		@temp_map[x][y].direction = 0
		@temp_map[x][y].closed = true
		#@temp_map[x][y].dist = @rand.rand(@variation)* 10
		#@temp_map[x][y].persistence = @persistence
		#@temp_map[x][y].persistence = @persistence
		searchSurroundingNodes(@temp_map[x][y])
		
		tempList = @open.asList
		for node in tempList
			@temp_map[node.x][node.y].dist = @rand.rand(@variation)* 10
			@temp_map[node.x][node.y].persistence = @persistence
			@temp_map[node.x][node.y].addNoise = true
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
				next_node.addNoise = true
				timeout = false
				if (next_node.dist <= 0)
					timeout = true
				end
				checkCostAndSetElevationAndColor(next_node)
				if !(timeout and next_node.persistence <= 0)
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
			node.persistence -= 1
		end
		node = chosenDirection(node)
		node.elevation = chosenElevation(node)
		
		#if node.elevation == @minElevation and node.persistence <= 0
		#	node.direction = -2
		#end
		
		@temp_map[node.x][node.y].elevation = node.elevation
		@temp_map[node.x][node.y].direction = node.direction
	end
	def chosenDirection(node)
		newDirection = 0
		if (node.dist <= 0)
		
			node.dist = @rand.rand(@variation) * 10
			newDirection = @rand.rand(0..2)
			
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
								if parent.persistence != -1
									current.persistence = parent.persistence
								end
								current.open = true
								@open.insertNode(current.x, current.y, current.cost)
								
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