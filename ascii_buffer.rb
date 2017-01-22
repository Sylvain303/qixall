# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# Ascci_Buffer is a 2 dimension Array of Fixnum representing Ascii Char.
#
# Usage:

class Ascci_Buffer
	def initialize(w,h, fill = ' ')
		@width, @height = w,h
		@empty = fill[0]
		@buffer = []
		(0...h).each { @buffer << Array.new(w, @empty) }
	end

	def [](x,y)
		raise "out of range" if x < 0 or x >= @width
		raise "out of range" if y < 0 or y >= @height
		@buffer[y][x]
	end

	def []=(x,y, v)
		raise "out of range" if x < 0 or x >= @width
		raise "out of range" if y < 0 or y >= @height
		if v.kind_of? String
			v.each_byte { |c| 
				case self[x,y]
				when @empty
					@buffer[y][x] = c
				when '-'[0]
					case c
					when '-'[0]
						@buffer[y][x] = '='[0]
					when '|'[0]
						@buffer[y][x] = '+'[0]
					else
						@buffer[y][x] = c
					end
				when '|'[0]
					case c
					when '-'[0]
						@buffer[y][x] = '+'[0]
					when '|'[0]
						@buffer[y][x] = '"'[0]
					else
						@buffer[y][x] = c
					end
				else
					@buffer[y][x] = c
				end
				x += 1
			}
		else
			raise "string expected"
		end
	end

	def to_s
		s = ""
		@buffer.each_with_index { |l, i|
			s << sprintf("%2d: ", i)
			l.each { |c| s << c.chr }
			s << "\n"
		}

		s
	end

	def line(x1, y1, x2, y2)
		if x1 == x2
			# V
			y1, y2 = y2, y1 if y1 > y2
			(y1..y2).each { |y| self[x1, y] = '|'[0] }
		elsif y1 == y2
			# H
			x1, x2 = x2, x1 if x1 > x2
			(x1..x2).each { |x| self[x, y1] = '-'[0] }
		else
			raise "not H or V line"
		end
		self
	end

	def draw_polygon(pol)
		pol.each_edge_with_index do |v1, v2, i1, i2| 
			# le nombre
			self[v1.x - 1, v1.y] = sprintf("%2d", i1) 
			begin 
				dir = pol.edge_dir(i1, i2)
			rescue PolygonError
				next
			end
			case dir
			when :up
				line(v1.x, v1.y - 1, v2.x, v2.y + 1)
			when :down
				line(v1.x, v1.y + 1, v2.x, v2.y - 1)
			when :left
				line(v1.x - 1, v1.y, v2.x + 1, v2.y)
			when :right
				line(v1.x + 1, v1.y, v2.x - 1, v2.y)
			end
		end
		self
	end

	def clear!(fill = ' ')
		(0...@width).each { |x| (0...@height).each { |y| @buffer[y][x] = fill } }
		self
	end
end

# short cut
def print_pol(*pols)
	ab = Ascci_Buffer.new(70,21)
	pols.each { |pol| ab.draw_polygon(pol) }
	print ab
end
