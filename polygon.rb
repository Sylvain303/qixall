# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8

# class Polygon: handle a set of points into a polygon structure
#                without graphical dependancies.
#
# See area.rb of graphical drawing of polygons.

require 'coord'

class PolygonError < RuntimeError
end

class Polygon
	def initialize(points = nil)#{{{
		#@x_min = @x_max = @y_min = @y_max = 0
		@closed = false
		@points = []

		if points.respond_to?(:each)
			points.each { |p| self << p }
			@closed = true
		else
			self << points if points
		end
	end#}}}

	attr_reader :closed
	attr_accessor :debug

	def [](index)
		@points.at(index)
	end

	def <<(p)#{{{
		raise "point already in Polygon : #{p} => #{self}" if @points.include?(p)

		# adapt 3 points lined up, remove middle point
		if @points.size >= 2 and
			( (@points[-2].x == p.x and @points[-1].x == p.x) or
			  (@points[-2].y == p.y and @points[-1].y == p.y) )
			puts "line up point: replace last: #{@points[-1]} <= p=#{p}"
			@points[-1] = p
		else
			@points << p
		end

		#@x_max = p.x if p.x > @x_max
		#@x_min = p.x if p.x < @x_min or @x_min == 0

		#@y_max = p.y if p.y > @y_max
		#@y_min = p.y if p.y < @y_min or @y_min == 0
		self
	end#}}}

	def pop
		if @points.size == 0
			raise "empty polygon"
		end

		last = @points.pop
		@closed = false

		last
	end

	def close
		@closed = true
		self
	end

	def reverse!
		@points.reverse!
		self
	end

	def find_nearest(val)#{{{
		near = -1
		found = nil
		@points.each_with_index do |p,i|
			d = yield(p, val).abs
			if d < near or near == -1
				near = d
				found = i
			end
		end

		found
	end#}}}

	def each_edge
		each_edge_with_index { |v1, v2| yield(v1, v2) }
	end

	def each_edge_with_index#{{{
		# loop over the closed Polygon 0 .. n + n,0
		for i in (@points.size+1..@points.size*2)

			i1 = (i - 1) % @points.size
			i2 = i % @points.size
			v1 = @points[i1]
			v2 = @points[i2]

			# skip last edge n, 0
			break if ! @closed && i2 == 0

			#print "#{i1}#{v1} => #{i2}#{v2}"
			yield(v1, v2, i1, i2)
		end
	end#}}}

	def each
		@points.each { |p| yield(p) }
	end
	alias each_points :each

	def size
    # number of points
		@points.size
	end

	# find_next_edge() return the index of nearest edge in the given motion#{{{
	# only work with player motion (x or y == 0)
	#
	# p Coord: current object position
	# motion Coord: velocity of the object
	#
	# return Integer or nil: the edge index in @points
	def find_next_edge(p, motion)
		dy = nil
		dx = nil
		memo = nil
		found = nil

		# puts " ----------- #{p}"
		raise "invalide motion #{motion}" if motion.x == 0 && motion.y == 0
		#raise "outside #{p}" if ! inside?(p.x, p.y)

		each_edge_with_index do |v1,v2, i1, i2|
			#puts "#{i1}#{v1} => #{i2}#{v2}"
			# motion H
			next if motion.x != 0 && v1.y == v2.y
			next if motion.x > 0  && v1.x < p.x
			next if motion.x < 0  && v1.x > p.x

			# (1,0) : right
			if motion.x > 0 && p.x < v1.x && ((v1.y <= p.y && p.y <= v2.y) or (v2.y <= p.y && p.y <= v1.y))
				dx = v1.x - p.x
				if memo == nil || dx < memo
						#puts " right hit #{v1} #{dx}"
						memo = dx
						found = i1
						next
				end
			end

			# (-1,0) : left
			if motion.x < 0 && p.x > v1.x && ((v1.y <= p.y && p.y <= v2.y) or (v2.y <= p.y && p.y <= v1.y))
				dx = p.x - v1.x
				if memo == nil || dx < memo
						#puts " left hit #{v1} #{dx}"
						memo = dx
						found = i1
						next
				end
			end

			# motion V
			next if motion.y != 0 && v1.x == v2.x
			next if motion.y > 0  && v1.y <  p.y
			next if motion.y < 0  && v1.y >  p.y

			# (0,1) : down
			if motion.y > 0 && p.y < v1.y && ((v1.x <= p.x && p.x <= v2.x) or (v2.x <= p.x && p.x <= v1.x))
				dy = v1.y - p.y
				if memo == nil || dy < memo
						#puts " down hit #{v1} #{dy}"
						memo = dy
						found = i1
						next
				end
			end

			# (0,-1) : up
			if motion.y < 0 && p.y > v1.y && ((v1.x <= p.x && p.x <= v2.x) or (v2.x <= p.x && p.x <= v1.x))
				dy = p.y - v1.y
				if memo == nil || dy < memo
						#puts " up hit #{v1} #{dy}"
						memo = dy
						found = i1
						next
				end
			end
		end

		return found
	end#}}}

	# find_nearest_edge(px, py) : return the edge index nearest to the point px, py #{{{
	#
	# algo:
	# 1. for each edge: compute the orthogonal distance
	#     ex: edge H
	#         +---k-----------------+
	#             |
	#             |
	#             p
	# 2. the orthogonal distance is between p and k
	# 3. k is for H edge: (p.x, v1.y) d = abs(p.y - v1.y)
	#    k is for V edge: (v1.x, p.y) d = abs(p.x - v1.x)
	# 4. if p is not "in front" of the edge, skip the edge
	def find_nearest_edge(px, py)
		min_d = nil
		edge = nil
		each_edge_with_index do |v1,v2, i1, i2|

			dir = edge_dir(i1, i2)
			if v1.x == v2.x # V
				if (dir == :down and (v1.y <= py and py <= v2.y)) or
						(dir == :up and (v2.y <= py and py <= v1.y))
					d = (px - v1.x).abs
				else
					# skip
					next
				end
			else # H
				if (dir == :right and (v1.x <= px and px <= v2.x)) or
						(dir == :left and (v2.x <= px and px <= v1.x))
					d = (py - v1.y).abs
				else
					# skip
					next
				end
			end

		if min_d.nil? or d < min_d
				min_d = d
				edge = i1
			end
		end

		return edge
	end#}}}

	def on_edge(edge, x, y)
		v1 = @points[edge]
		v2 = @points[next_corner(edge)]

		# bool detecting Vertical or Horizontal edge
		return ( ( (v1.x == x && v2.x == v1.x) && (v1.y <= y && y <= v2.y or v2.y <= y && y <= v1.y) )  or #V
			       ( (v1.y == y && v2.y == v1.y) && (v1.x <= x && x <= v2.x or v2.x <= x && x <= v1.x) )   ) #H
	end

	def edge_dir(start_edge, end_edge)
		edge_dir = @points[end_edge] - @points[start_edge]
		case
		when edge_dir.x == 0 && edge_dir.y > 0
			:down
		when edge_dir.x == 0 && edge_dir.y < 0
			:up
		when edge_dir.x > 0 && edge_dir.y == 0
			:right
		when edge_dir.x < 0 && edge_dir.y == 0
			:left
		else
			raise PolygonError, "invalide edge #{start_edge} => #{end_edge}"
		end
	end

	# next_corner(index) : return the next index in @points looping to the start if needed
	def next_corner(old)
		(old + 1 + @points.size) % @points.size
	end

	def prev_corner(old)
		(old - 1 + @points.size) % @points.size
	end

	def get_edge(edge_index)
		# return the pair of points forming the edge
		nedge = next_corner(edge_index)
		case edge_dir(edge_index, nedge)
		when :up, :left
			# revese it for simpler usage
			return @points[nedge], @points[edge_index]
		when :down, :right
			return @points[edge_index], @points[nedge]
		end
	end

	def inside?(x, y, match_edge = true)#{{{
		#puts "test inside #{x},#{y}"

		#puts "x_min=#{@x_min}"
		#puts "x_max=#{@x_max}"
		#puts "y_min=#{@y_min}"
		#puts "y_max=#{@y_max}"

		#puts "x_min=#{x < @x_min}"
		#puts "y_min=#{y < @y_min}"
		#puts "x_max=#{x > @x_max}"
		#puts "y_max=#{y > @y_max}"

		raise PolygonError, "Polygon not closed" if ! @closed

		cn = 0
		#if x < @x_min && y < @y_min or x > @x_max && y > @y_max
		#	return false
		#else
			#i = find_nearest_y(y)
			each_edge do |v1,v2|

				# detect if the point is on the edge itself
				if ( (v1.x == x && v2.x == v1.x) && (v1.y <= y && y <= v2.y or v2.y <= y && y <= v1.y) )  or #V
				   ( (v1.y == y && v2.y == v1.y) && (v1.x <= x && x <= v2.x or v2.x <= x && x <= v1.x) )     #H
					#puts "on edge"
					return match_edge
				end

				# don't test horizontal edge
				if v1.y == v2.y
					#puts " H"
					next
				end

				if v1.y <= y && y <  v2.y or # upward crossing
					 v2.y <= y && y <  v1.y    # downward crossing

					if x < v1.x
					   cn += 1
					end
				end

				#puts " V #{cn}"
			end
		#end

		#puts "Fin #{cn}"
		return cn % 2 == 1 ? true : false # 0 if even => out, 1 if odd => in
	end#}}}

	def zoom(factor)#{{{
		pol = Polygon.new

		# compute the first point for translating to its old coordinate
		first = @points.first
		n = Coord.new(first.x * factor, first.y * factor)
		delta = n - first

		# recompute all points
		@points.each {|p| pol << Coord.new(p.x * factor - delta.x, p.y * factor - delta.y) }

		pol.close if @closed

		return pol
	end#}}}

	def translate(x, y)
		@points.each { |p|
			p.x += x
			p.y += y
		}
		self
	end

	def dup
		n = Polygon.new
		n.replace!(self)
		n.close if @closed

		n
	end

	def replace!(pol)
		@points.clear
		pol.each { |p| @points << p.dup }
		@closed = pol.closed
		self
	end

	def cut(tail, start_edge, end_edge)#{{{
		raise PolygonError, "Polygon not closed" if ! @closed

		raise "tail doesn't reach start_edge" if ! on_edge(start_edge, tail[0].x,  tail[0].y)
		raise "tail doesn't reach end_edge"   if ! on_edge(end_edge,   tail[-1].x, tail[-1].y)
		raise "tail has not enough point: #{tail}" if tail.size <= 1

		pol1 = Polygon.new
		pol2 = Polygon.new

		# process of linking the 2 polygon
		# 1. add each point of the area from 0 to the point before the tail
		# 2. add each point of the tail
		# 3. close the area, by adding the point after the tail throught the end of the area
		#
		# the other polygon is build with
		# 1. all the tail points
		# 2. the area points from where the tail ends in reverse order throught where the tail starts

		# test swaping start_edge > end_edge{{{
		if start_edge > end_edge
			puts "swapped #{end_edge} => #{start_edge}" if @debug
			start_edge, end_edge = end_edge, start_edge
			tail.points.reverse!
		end

		if start_edge == end_edge
			# tail starts and stops on the same area's edge
			puts "same edge = #{start_edge}" if @debug
			edir = edge_dir(start_edge, next_corner(start_edge))
			tdir = tail.edge_dir(0, -1)

			puts "edir=#{edir}, tdir=#{tdir}" if @debug

			if edir != tdir
				tail.points.reverse!
			end
		end

		# }}}

		pol1_end = start_edge
		pol1_start = end_edge + 1
		pol2_start = pol1_end + 1 # == start_edge + 1   pol2 works reversed !!
		pol2_end = pol1_start - 1 # == end_edge

		pol1_start_tail = 0
		pol1_end_tail = tail.size - 1
		pol2_start_tail = 0
		pol2_end_tail = tail.size - 1

		puts "before: pol1_end=#{pol1_end} pol1_start=#{pol1_start}" if @debug
		puts "before: pol2_start=#{pol2_start} pol2_end=#{pol2_end}" if @debug
		puts "before: pol1_start_tail=#{pol1_start_tail} pol1_end_tail=#{pol1_end_tail}" if @debug
		puts "before: pol2_start_tail=#{pol2_start_tail} pol2_end_tail=#{pol2_end_tail}" if @debug

		# test on_corner# {{{
		# start_edge {{{
		if tail[0] == @points[start_edge]
			puts "on_corner tail 0 => start_edge" if @debug
			pol1_end -= 1
			if tail[0].x == @points[pol1_end].x && @points[pol1_end].x == tail[1].x or
				 tail[0].y == @points[pol1_end].y && @points[pol1_end].y == tail[1].y

				 pol1_start_tail += 1
			end
			if tail[0].x == @points[pol2_start].x && @points[pol2_start].x == tail[1].x or
				 tail[0].y == @points[pol2_start].y && @points[pol2_start].y == tail[1].y

				 pol2_start_tail += 1
			end
		end

		if tail[0] == @points[next_corner(start_edge)]
			puts "on_corner tail 0 next_corner(start_edge)" if @debug
			pol2_start += 1
			if tail[0].x == @points[pol1_end].x && @points[pol1_end].x == tail[1].x or
				 tail[0].y == @points[pol1_end].y && @points[pol1_end].y == tail[1].y

				 pol1_start_tail += 1
			end
			if tail[0].x == @points[pol2_start].x && @points[pol2_start].x == tail[1].x or
				 tail[0].y == @points[pol2_start].y && @points[pol2_start].y == tail[1].y

				 pol2_start_tail += 1
			end
		end

		if start_edge !=  end_edge && tail[0] == @points[end_edge]
			raise "on_corner tail 0 end_edge is it possible??"
		end

		if start_edge !=  end_edge && @points[next_corner(end_edge)] == tail[0]
			raise "on_corner tail 0 next_corner(end_edge) is it possible??"
		end
		#}}}

		#  end_edge {{{
		if @points[end_edge] == tail[-1]
			puts "on_corner tail -1 => end_edge" if @debug
			pol2_end -= 1
			if tail[-2].x == @points[pol1_start].x && @points[pol1_start].x == tail[-1].x or
				 tail[-2].y == @points[pol1_start].y && @points[pol1_start].y == tail[-1].y

				 pol1_end_tail -= 1
			end
			if tail[-2].x == @points[pol2_end].x && @points[pol2_end].x == tail[-1].x or
				 tail[-2].y == @points[pol2_end].y && @points[pol2_end].y == tail[-1].y

				 pol2_end_tail -= 1
			end
		end

		if @points[next_corner(end_edge)] == tail[-1]
			puts "on_corner tail -1 next_corner(end_edge)" if @debug
			pol1_start += 1
			if tail[-2].x == @points[pol1_start].x && @points[pol1_start].x == tail[-1].x or
				 tail[-2].y == @points[pol1_start].y && @points[pol1_start].y == tail[-1].y

				 pol1_end_tail -= 1
			end
			if tail[-2].x == @points[pol2_end].x && @points[pol2_end].x == tail[-1].x or
				 tail[-2].y == @points[pol2_end].y && @points[pol2_end].y == tail[-1].y

				 pol2_end_tail -= 1
			end
		end

		if start_edge != end_edge && @points[start_edge] == tail[-1]
			raise "on_corner tail -1 start_edge is it possible??"
		end

		if start_edge != end_edge && @points[next_corner(start_edge)] == tail[-1]
			raise "on_corner tail -1 next_corner(start_edge) is it possible??"
		end
		#}}}
		# }}}

		puts "after: pol1_end=#{pol1_end} pol1_start=#{pol1_start}" if @debug
		puts "after: pol2_start=#{pol2_start} pol2_end=#{pol2_end}" if @debug
		puts "after: pol1_start_tail=#{pol1_start_tail} pol1_end_tail=#{pol1_end_tail}" if @debug
		puts "after: pol2_start_tail=#{pol2_start_tail} pol2_end_tail=#{pol2_end_tail}" if @debug

		# create 2 Polygon, self and other
		# add start point in pol1 including start_edge
		@points[0..pol1_end].each { |p| pol1 << p.dup }

		# copy tail into pol1 and pol2
		tail.points[pol1_start_tail..pol1_end_tail].each { |p| pol1 << p.dup }
		tail.points[pol2_start_tail..pol2_end_tail].each { |p| pol2 << p.dup }

		# finish completing pol1 with point following tail where it reaches area on end_edge
		@points[pol1_start...@points.size].each { |p| pol1 << p.dup }

		# close pol2 reversing the area between start_edge and end_edge
		@points[pol2_start..pol2_end].reverse.each { |p| pol2 << p.dup }

		pol1.close
		pol2.close

		return pol1, pol2
	end#}}}

	def Polygon.load(iostream)
		Polygon.new.load(iostream)
	end

	def load(iostream)
		iostream.each_line do |l|
      begin
        next if l =~ /^(#|\s*$)/
      rescue ArgumentError => e
        puts "line pasing error '#{e}, ignoring : #{l}"
        next
      end

      # Match but not required
			next if l =~ /Polygon:/
			self << Coord.load(l)
		end
		self
	end

	def dump(iostream)
		iostream.puts self.to_s
		self
	end

	def to_s
		s = "Polygon:\n"
		@points.each_with_index { |p,i| s += "#{i} #{p}\n" }
		s
	end

  # find min and max points
  def find_min_max(shift_coord=nil)
    min = Coord.new(-1, -1)
    max = Coord.new(-1, -1)
		@points.each { |p|
      if min.x == -1 or min.x > p.x
        min.x = p.x
      end
      if min.y == -1 or min.y > p.y
        min.y = p.y
      end

      if max.x == -1 or max.x < p.x
        max.x = p.x
      end
      if max.y == -1 or max.y < p.y
        max.y = p.y
      end

		}

    if shift_coord.nil?
      return min, max
    else
      return min - shift_coord, max - shift_coord
    end
  end

  # convert polygon to an array of all coordinate x and y
  def to_a
    a = @points.collect {|p| [p.x, p.y] }.flatten
    if @closed
      a << @points.first.x
      a << @points.first.y
    end
    return a
  end

protected
	attr_reader :points

end
