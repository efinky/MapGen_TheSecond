require 'rubygems'



class LinkedList
	attr_reader :count
	def initialize
		@node_struct = Struct.new :next, :prev, :x, :y, :index
		@head = nil
		@count = 0
		
	end
	
	def asList
		nodes = Array.new
		current = @head
		while current != nil
			nodes.push(current)
			
			#puts "x = " + current.x.to_s + " y = " + current.y.to_s + " i = " + current.index.to_s
			current = current.next
		end
		return nodes
	end
	
	def insertNode(x, y, index)
		#list is empty
		result = -1
		if @head == nil
			@head = @node_struct.new nil, nil, x, y, index
			result = 0
			#puts "first" + index.to_s
		else
			current = @head
			prev = nil
			#searches until we find the right place in the list
			while current.next != nil and index >= current.index
				current = current.next
			end
			#we are at the front of the list
			if current == @head and index < current.index
				#insert at front of list
				#puts "i = " + index.to_s + " c = " + current.index.to_s
				#puts "insert in front" + index.to_s
				result = 0
				new_node = @node_struct.new @head, nil, x, y, index
				@head.prev = new_node
				@head = new_node
					
			#we are at the end of the list
			elsif current.next == nil and index >= current.index
				result = 0
				#place new node at the end of list
				#puts "insert at end" + index.to_s
				new_node = @node_struct.new nil, current, x, y, index
				current.next = new_node			
			elsif index < current.index
				result = 0
				#puts "insert in middle1 " + index.to_s
				new_node = @node_struct.new current, current.prev, x, y, index
				current.prev.next = new_node
				current.prev = new_node
				#puts "inserted" + index.to_s
			else
				result = 0
				#puts "insert in middle2 " + index.to_s
				new_node = @node_struct.new current.next, current, x, y, index
				current.next.prev = new_node
				current.next = new_node
				#puts "inserted" + index.to_s
			end
			
		end
		if result == 0
			@count += 1
		end
		return result
	end
	
	#pops the first node of the list, 
	#by default this node will have the lowest index (or cost)
	def popNode()
		if @head != nil
			x = @head.x
			y = @head.y
			index = @head.index
			
			#delete the first node 
			if @head.next != nil
				@head.next.prev = nil
				@head = @head.next
			else
				@head = nil
			end
			@count -= 1
			
			#return relevant information 
			return x, y
		else
			return -1, -1
		end
	end
	
	def print
		temp = @head
		while temp != nil
			puts "x = " + temp.x.to_s + " y = " + temp.y.to_s + " i = " + temp.index.to_s
			temp = temp.next
		end
	end
	

end
