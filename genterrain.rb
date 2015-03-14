require 'rubygems'
require 'perlin'

class GenTerrain
	attr_reader :map
	def initialize(length, seed, map)
		puts "here"
		@length = length 
		@map = map
		# Takes values seed, persistence, and octaves
		gen = Perlin::Generator.new seed, 0.5, 12
		#gen = Perlin::Generator.new seed, 0.5, 4
		#gen = Perlin::Generator.new seed, 0.5, 1
		#gen = Perlin::Generator.new seed, 0.25, 4
		#gen = Perlin::Generator.new seed, 0.5, 12
		
		for i in (0..@length-1)
			for j in (0..@length-1)
				if @map[i][j].elevation == -1
					@map[i][j].elevation = ((gen[i, j]).abs*10).to_i
				else
					@map[i][j].elevation = ((gen[i, j]).abs*10).to_i+@map[i][j].elevation%10
				end
			end
		end
		#smoothMap
		#smoothMap
	
	end
	def getSurroundingNodesElevation(x, y)
		temp_a = Array.new
		for i in (x-1..x+1)
			for j in (y-1..y+1)
				if (i >= 0 and j >= 0 and i < @length and j < @length)
					if (@map[i][j].elevation != -1)
						temp_a.push(@map[i][j])
					end
				end
			end
		end
		return temp_a
	end 
	def smoothMap
		for i in (0..@length-1)
			for j in (0..@length-1)
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
end