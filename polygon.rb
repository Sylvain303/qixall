# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
#
# coding: utf-8
#
# class Polygon: handle a set of points into a polygon structure
#                without graphical dependancies.
#
# See area.rb for graphical drawing of polygons.

require 'coord'

class PolygonError < RuntimeError
end

class Polygon
	def initialize(points = nil)#{{{
    # store min and max internal coord, they are not necessarly on the
    # polygon
		@min = Coord.new(-1, -1)
    @max = Coord.new(-1, -1)

		@closed = false
		@points = []

    # if initialized with something else, points must contains Coord
		if points.respond_to?(:each)
			points.each { |p| self << p }
      if points.respond_to?(:close)
        close
      end
		else
			self << points if points
		end
	end#}}}

	attr_reader :closed, :min, :max
	attr_accessor :debug

	def [](index)#{{{
		@points.at(index)
	end#}}}

	def <<(p)#{{{
    if @points.include?(p)
      raise PolygonError, "point already in Polygon : #{p} => #{self}"
    end

		# adapt 3 points lined up, remove middle point
		if @points.size >= 2 and
			( (@points[-2].x == p.x and @points[-1].x == p.x) or
			  (@points[-2].y == p.y and @points[-1].y == p.y) )
			puts "line up point: replace last: #{@points[-1]} <= p=#{p}"
			@points[-1] = p
		else
			@points << p
		end

    update_min_max!(p)
		self
	end#}}}

	def pop#{{{
		if @points.size == 0
			raise PolygonError, "empty polygon"
		end

		last = @points.pop
		@closed = false

    # update min max
    @min, @max = find_min_max
		last
	end#}}}

	def close#{{{
		# ensure that the last point closes with the first point
		sp, ep = @points[0], @points[-1]
		if sp.x != ep.x and sp.y != ep.y
			raise PolygonError, "points #{ep} => #{sp} wont close"
		end

		@closed = true
		self
	end#}}}

	def reverse!#{{{
		@points.reverse!
		self
	end#}}}

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

	def each_edge#{{{
		each_edge_with_index { |v1, v2| yield(v1, v2) }
	end#}}}

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

	def each#{{{
		@points.each { |p| yield(p) }
	end#}}}
	alias each_points :each

	def size#{{{
    # number of points
		@points.size
	end#}}}

	# find_next_edge(p, motion) return the index of nearest edge in the given motion#{{{
	# only work with player orthogonal motion (x or y == 0)
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
			if motion.x > 0 && p.x < v1.x && ((v1.y <= p.y && p.y <= v2.y) or
                                        (v2.y <= p.y && p.y <= v1.y))
				dx = v1.x - p.x
				if memo == nil || dx < memo
						#puts " right hit #{v1} #{dx}"
						memo = dx
						found = i1
						next
				end
			end

			# (-1,0) : left
			if motion.x < 0 && p.x > v1.x && ((v1.y <= p.y && p.y <= v2.y) or
                                        (v2.y <= p.y && p.y <= v1.y))
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
			if motion.y > 0 && p.y < v1.y && ((v1.x <= p.x && p.x <= v2.x) or
                                        (v2.x <= p.x && p.x <= v1.x))
				dy = v1.y - p.y
				if memo == nil || dy < memo
						#puts " down hit #{v1} #{dy}"
						memo = dy
						found = i1
						next
				end
			end

			# (0,-1) : up
			if motion.y < 0 && p.y > v1.y && ((v1.x <= p.x && p.x <= v2.x) or
                                        (v2.x <= p.x && p.x <= v1.x))
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

	# on_edge(edge, x, y) test if point x, y is on edge #{{{
	def on_edge(edge, x, y)
		v1 = @points[edge]
		v2 = @points[next_corner(edge)]

		# bool detecting Vertical or Horizontal edge
		return ( ( (v1.x == x && v2.x == v1.x) && (v1.y <= y && y <= v2.y or v2.y <= y && y <= v1.y) )  or #V
			       ( (v1.y == y && v2.y == v1.y) && (v1.x <= x && x <= v2.x or v2.x <= x && x <= v1.x) )   ) #H
	end#}}}

	def edge_dir(start_edge, end_edge)#{{{
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
	end#}}}

	# next_corner(index) : return the next index in @points#{{{
  # looping to the start if needed
	def next_corner(old)
		(old + 1 + @points.size) % @points.size
	end#}}}

	def prev_corner(old)#{{{
		(old - 1 + @points.size) % @points.size
	end#}}}

	# get_edge(edge_index) return the pair of points forming the edge#{{{
	def get_edge(edge_index)
		nedge = next_corner(edge_index)
		case edge_dir(edge_index, nedge)
		when :up, :left
			# revese it for simpler usage
			return @points[nedge], @points[edge_index]
		when :down, :right
			return @points[edge_index], @points[nedge]
		end
	end#}}}

	def inside?(x, y, match_edge = true)#{{{
		raise PolygonError, "Polygon not closed" if ! @closed

		cn = 0
		#if x < @x_min && y < @y_min or x > @x_max && y > @y_max
		#	return false
		#else
			#i = find_nearest_y(y)
			each_edge do |v1,v2|

				# detect if the point is on the edge itself
				if ( (v1.x == x && v2.x == v1.x) && (v1.y <= y && y <= v2.y or
                                             v2.y <= y && y <= v1.y) )  or #V
				   ( (v1.y == y && v2.y == v1.y) && (v1.x <= x && x <= v2.x or
                                             v2.x <= x && x <= v1.x) )     #H
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

		# compute the first point for keeping the polygon to its old
    # start coordinate
		first = @points.first
		n = Coord.new(first.x * factor, first.y * factor)
		delta = n - first

		# recompute all points, shifted to origin
		@points.each_with_index {|p, i|
      pol << Coord.new(p.x * factor - delta.x, p.y * factor - delta.y)
    }

		pol.close if @closed

		return pol
	end#}}}

	def translate(x, y)#{{{
		@points.each { |p|
			p.x += x
			p.y += y
      update_min_max!(p)
		}
		self
	end#}}}

	def dup#{{{
		n = Polygon.new
		n.replace!(self)
		n.close if @closed

		n
	end#}}}

	def replace!(pol)#{{{
		@points.clear
		pol.each { |p| @points << p.dup }
		@closed = pol.closed
		self
	end#}}}

	# cut(tail, start_edge, end_edge) compute polygon cut with tail #{{{
  # cut is used in player.rb when it reachs some other edge of the surrounding
  # area. start_edge, end_edge, are index in the polygon @points.
  #
  # return 2 new polygons, from each side of the cutting polygon
  # tail can be reversed.
  # self is not modified.
	def cut(tail, start_edge, end_edge)
		raise PolygonError, "Polygon not closed" if ! @closed

		raise "tail doesn't reach start_edge" if ! on_edge(start_edge, tail[0].x,  tail[0].y)
		raise "tail doesn't reach end_edge"   if ! on_edge(end_edge,   tail[-1].x, tail[-1].y)
		raise "tail has not enough point: #{tail}" if tail.size <= 1

		pol1 = Polygon.new
		pol2 = Polygon.new

		# process of linking the 2 polygons:
		# 1. add each point of the area from 0 to the point before the tail
		# 2. add each point of the tail
    # 3. close the area, by adding the point after the tail throught the end of
    #    the area
		#
		# the other polygon is build with:
		# 1. all the tail points
		# 2. the area points from where the tail ends in reverse order throught
    #    where the tail starts

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

    if @debug
      puts "before: pol1_end=#{pol1_end} pol1_start=#{pol1_start}"
      puts "before: pol2_start=#{pol2_start} pol2_end=#{pol2_end}"
      puts "before: pol1_start_tail=#{pol1_start_tail} " +
        "pol1_end_tail=#{pol1_end_tail}"
      puts "before: pol2_start_tail=#{pol2_start_tail} " +
        "pol2_end_tail=#{pol2_end_tail}"
    end

		# test on_corner #{{{
    # If the tail is started on a corner we skip the corner on copying
    # into the destination polygon.
    
		# start_edge {{{
		if tail[0] == @points[start_edge]
			puts "on_corner tail 0 => start_edge" if @debug
			pol1_end -= 1
			if tail[0].x == @points[pol1_end].x && @points[pol1_end].x == tail[1].x or
				 tail[0].y == @points[pol1_end].y && @points[pol1_end].y == tail[1].y

				 pol1_start_tail += 1
			end
			if tail[0].x == @points[pol2_start].x &&
         @points[pol2_start].x == tail[1].x or
				 tail[0].y == @points[pol2_start].y &&
         @points[pol2_start].y == tail[1].y

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
			if tail[0].x == @points[pol2_start].x &&
         @points[pol2_start].x == tail[1].x or
				 tail[0].y == @points[pol2_start].y &&
         @points[pol2_start].y == tail[1].y

				 pol2_start_tail += 1
			end
		end

    # this check is invalid it happens, See unittest.
		#if start_edge != end_edge && tail[0] == @points[end_edge]
		#	raise "on_corner tail 0 on end_edge is it possible??"
		#end

    # what about this one?
		if start_edge != end_edge && @points[next_corner(end_edge)] == tail[0]
			raise "on_corner tail 0 on next_corner(end_edge) is it possible??"
		end
		#}}}

		# end_edge {{{
    # Does the tail arrive on a corner?
    # the point will be skipped too.
		if @points[end_edge] == tail[-1]
			puts "on_corner tail -1 => end_edge" if @debug
			pol2_end -= 1
			if tail[-2].x == @points[pol1_start].x &&
         @points[pol1_start].x == tail[-1].x or
				 tail[-2].y == @points[pol1_start].y &&
         @points[pol1_start].y == tail[-1].y

				 pol1_end_tail -= 1
			end
			if tail[-2].x == @points[pol2_end].x &&
         @points[pol2_end].x == tail[-1].x or
				 tail[-2].y == @points[pol2_end].y &&
         @points[pol2_end].y == tail[-1].y

				 pol2_end_tail -= 1
			end
		end

		if @points[next_corner(end_edge)] == tail[-1]
			puts "on_corner tail -1 next_corner(end_edge)" if @debug
			pol1_start += 1
			if tail[-2].x == @points[pol1_start].x &&
         @points[pol1_start].x == tail[-1].x or
				 tail[-2].y == @points[pol1_start].y &&
         @points[pol1_start].y == tail[-1].y

				 pol1_end_tail -= 1
			end
			if tail[-2].x == @points[pol2_end].x &&
         @points[pol2_end].x == tail[-1].x or
				 tail[-2].y == @points[pol2_end].y &&
         @points[pol2_end].y == tail[-1].y

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

    if @debug
      puts "after: pol1_end=#{pol1_end} pol1_start=#{pol1_start}"
      puts "after: pol2_start=#{pol2_start} pol2_end=#{pol2_end}"
      puts "after: pol1_start_tail=#{pol1_start_tail} " +
        "pol1_end_tail=#{pol1_end_tail}"
      puts "after: pol2_start_tail=#{pol2_start_tail} " +
        "pol2_end_tail=#{pol2_end_tail}"
    end

		# create 2 Polygon, self and other
		# add start point in pol1 including start_edge
		@points[0..pol1_end].each { |p| pol1 << p.dup }

		# copy tail into pol1 and pol2
		tail.points[pol1_start_tail..pol1_end_tail].each { |p| pol1 << p.dup }
		tail.points[pol2_start_tail..pol2_end_tail].each { |p| pol2 << p.dup }

    # finish completing pol1 with point following tail where it reaches area on
    # end_edge
		@points[pol1_start...@points.size].each { |p| pol1 << p.dup }

		# close pol2 reversing the area between start_edge and end_edge
		@points[pol2_start..pol2_end].reverse.each { |p| pol2 << p.dup }

		pol1.close
		pol2.close

		return pol1, pol2
	end#}}}

	def Polygon.load(iostream)#{{{
		Polygon.new.load(iostream)
	end#}}}

	def load(iostream)#{{{
		iostream.each_line do |l|
      begin
        next if l =~ /^(#|\s*$)/
      rescue ArgumentError => e
        # UTF8 encoding mix
        puts "line pasing error '#{e}, ignoring : #{l}"
        next
      end

      # Match but not required
			next if l =~ /Polygon:/

      # closing
			if l =~ /closed=true/
        self.close
        # stop parsing
        break
      end

      # default add as a Coord
			self << Coord.load(l)
		end
		self
	end#}}}

	def dump(iostream)#{{{
		iostream.puts self.to_s
		self
	end#}}}

	def to_s#{{{
		s = "Polygon:\n"
		@points.each_with_index { |p,i| s += "#{i} #{p}\n" }
    s += "closed=true\n" if @closed
		s
	end#}}}

  # find min and max points enclosing the polygon
  def find_min_max(shift_coord=nil)#{{{
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
  end#}}}

  # to_a : convert polygon to an flat array of all coordinates x and y#{{{
  def to_a
    a = @points.collect {|p| [p.x, p.y] }.flatten
    if @closed
      a << @points.first.x
      a << @points.first.y
    end
    return a
  end#}}}

  # surface() : compute polygon surface#{{{
  # adapted from:
  # https://fr.wikipedia.org/wiki/Aire_et_centre_de_masse_d%27un_polygone
  # and
  # https://openclassrooms.com/forum/sujet/l-aire-d-un-polygone-28783#message-3617386
  def surface
    a = 0
    # slice (size - 2) gives 0..n-1
    p0 = @points[0]
    @points[0..@points.size - 2].each_with_index {|p, i|
      d1 = (p.x - p0.x) * (@points[i+1].y - p0.y)
      d2 = (@points[i+1].x - p0.x) * (p.y - p0.y)
      a += d1 - d2
    }
    return (a / 2).abs
  end#}}}
protected
	attr_reader :points

  def update_min_max!(p)#{{{
    # p must be a point of the polygon
		@max.x = p.x if p.x > @max.x
		@min.x = p.x if p.x < @min.x or @min.x == -1

		@max.y = p.y if p.y > @max.y
		@min.y = p.y if p.y < @min.y or @min.y == -1

    self
  end#}}}
end
