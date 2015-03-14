require 'rubygems'
require 'gosu'
require './mapgennew'
 


#load images for terrain
#terrain has properties like... if it can be walked on...
#
#generate chunks of terrain... 
#
#
$Width = 300#1024
$Height = 300#768
$MapRows = 600
class GameWindow < Gosu::Window
	def initialize
		#+98 adds a black buffer around the edge
		super $Width+98, $Height+98, false
		self.caption = "Map Generator"
		@w = $Width/10
		@h = $Height/10
		@map = MapGen.new(self, @w, @h,$MapRows)
		bitmap_name = @map.bitmap_name
		@background_image = Gosu::Image.new(self, bitmap_name, true)
		
	end
	
		
	#escape to close
	def button_down(id)
		case id
		#escape to close game
		when Gosu::KbEscape
			self.close		
		end
	end
	def draw
		@background_image.draw(0, 0, 0)
	end
end
 
window = GameWindow.new
window.show



