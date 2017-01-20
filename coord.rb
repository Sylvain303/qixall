# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# class Coord - manipulate coordinate couple on Integer (x, y)
#

class Coord#{{{
	def initialize(x,y)
		@x, @y = x.to_i, y.to_i
	end
	attr_accessor :x, :y

	def long(other, epais)
		dx = (@x - other.x).abs
		dy = (@y - other.y).abs
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

	def +(other)
		Coord.new(@x + other.x, @y + other.y)
	end
	def -(other)
		Coord.new(@x - other.x, @y - other.y)
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

	def snap(gird_tickness)
		dx = @x % gird_tickness
		dy = @y % gird_tickness

		if dx != 0
			if dx - gird_tickness / 2 > 0
				nx = @x + (gird_tickness -dx)
			else
				nx = @x - dx
			end
		else
			nx = @x
		end	

		if dy != 0
			if dy - gird_tickness / 2> 0
				ny = @y + (gird_tickness -dy)
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
			raise "Coord.load not found in string:'#{l}'"
		end
	end

	def to_s
		"(#@x,#@y)"
	end
end#}}}

