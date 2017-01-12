# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
class Coord#{{{
	def initialize(x,y)
		@x, @y = x.to_i, y.to_i
	end
	attr_accessor :x, :y

	def long(autre, epais)
		dx = (@x - autre.x).abs
		dy = (@y - autre.y).abs
		if dx > dy
			if dx  > epais
				# long = dx
				dy = 0 
			else
				dx = dy = 0
			end
		else
			if dy  > epais
				# long = dy
				dx = 0 
			else
				dx = dy = 0
			end
		end
		Coord.new(dx, dy)
	end

	def +(autre)
		Coord.new(@x + autre.x, @y + autre.y)
	end
	def -(autre)
		Coord.new(@x - autre.x, @y - autre.y)
	end
	
	def move_by(other)
		@x += other.x
		@y += other.y
	end

	def copy_x(long)
		Coord.new(@x, @y + long)
	end
	def copy_y(long)
		Coord.new(@x + long, @y)
	end

	def dup
		Coord.new(@x, @y)
	end

	def snap(epais)
		dx = @x % epais
		dy = @y % epais

		if dx != 0
			if dx - epais / 2 > 0
				nx = @x + (epais -dx)
			else
				nx = @x - dx
			end
		else
			nx = @x
		end	

		if dy != 0
			if dy - epais / 2> 0
				ny = @y + (epais -dy)
			else
				ny = @y - dy
			end
		else
			ny = @y
		end	

		Coord.new(nx, ny)
	end

	def Coord.snap?(x, y, grid)
		x % grid == 0 && y % grid == 0	
	end

	def is?(x, y)
		@x == x && @y == y
	end

	def ==(other)
		is?(other.x, other.y)
	end

	def Coord.load(l)
		if l =~ /\((\d+),\s*(\d+)\)/
			Coord.new($1, $2)
		else
			raise "Coord.load not found in :'#{l}'"
		end
	end
	def to_s
		"(#@x,#@y)"
	end
end#}}}

