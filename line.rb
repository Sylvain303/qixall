# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#

# Line handle Horizontal or Vertical line, set by two points. This class is used
# to render class Area. It encapsulate line with a thickness rendered by a draw_quad
#
# needs to know the window to draw itself
class Line#{{{
	def initialize(window, p1, p2)
		@window = window

		@p1 , @p2 = p1, p2

		@thickness = @window.epais
		@l = p1.long(p2, @thickness)

		@color =  0xFFFF00FF

		d = @p1 - @p2
		w = h = 0

		if d.x == 0 && d.y != 0
			# vertical
			w = @thickness / 2
		elsif d.x != 0 && d.y == 0
			# horizontal
			h = @thickness / 2
		else
			# you must hanle the exception by discaring the last point.
			raise "not HV line d : #{d} (#{p1}, #{p2})"
		end

		@c = []

		@c[0] = Coord.new(@p1.x - w, @p1.y - h)
		@c[1] = Coord.new(@p1.x + w, @p1.y + h)
		@c[2] = Coord.new(@p2.x - w, @p2.y - h)
		@c[3] = Coord.new(@p2.x + w, @p2.y + h)
	end

	attr_accessor :color

	def to_s
		"#@p1, #@p2 : #@l"
	end

	def draw
		@window.draw_quad(@c[0].x, @c[0].y, @color,
				          @c[1].x, @c[1].y, @color,
				          @c[2].x, @c[2].y, @color,
				          @c[3].x, @c[3].y, @color,
				          ZOrder::Lines, mode=:default)
		self
	end
	
end#}}}


