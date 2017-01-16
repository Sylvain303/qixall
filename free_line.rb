# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#

# FreeLine handle a simple line set by two points.

require 'coord'

# needs to know the window to draw itself
class FreeLine#{{{
	def initialize(window, p1, p2)
		@window = window

		@p1, @p2 = p1, p2

		@thickness = @window.epais
		@color =  0xFFFF00FF
	end

	attr_accessor :color

	def to_s
		"#@p1, #@p2"
	end

	def draw
		@window.draw_line(@p1.x, @p1.y, @color,
				          @p2.x, @p2.y, @color,
				          ZOrder::Lines, mode=:default)
		self
	end
end#}}}


