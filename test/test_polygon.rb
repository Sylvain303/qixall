# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
require 'test/unit'
require 'polygon'
require 'stringio'
require 'ascii_buffer'

class TC_Polygon < Test::Unit::TestCase
	def setup# {{{
		input = StringIO.new(<<-FIN)
0 (51,102)
1 (102,102)
2 (102,51)
3 (204,51)
4 (204,102)
5 (255,102)
6 (255,51)
7 (306,51)
8 (306,102)
9 (408,102)
10 (408,153)
11 (306,153)
12 (306,204)
13 (357,204)
14 (357,255)
15 (408,255)
16 (408,306)
17 (255,306)
18 (255,255)
19 (204,255)
20 (204,153)
21 (153,153)
22 (153,306)
23 (51,306)
		FIN

		@pol2 = Polygon.load(input)
		@pol2.close

		@input = StringIO.new(<<-FIN)
0 (1,1)
1 (5,1)
2 (5,5)
3 (1,5)
		FIN
	end# }}}

	def assert_not_same_points(*pols)# {{{
		return if pols.size == 1
		# test distinct points for each polygon: pol2, np1, np2
		seen = {}
		p1 = pols.first
		assert_block("point not duplicated") do
			r = true
			# fetch first polygon
			p1.each { |i| seen[p.object_id] = 1 }
			# test all next polygon
			(1...pols.size).each do |i| 
				pols[i].each { |p| 
					if seen[p.object_id]
						r = false
						break
					else
						seen[p.object_id] = 1
					end
				}

				break if ! r
			end

			r
		end
	end# }}}

	def test_load# {{{
		pol = nil
		File.open("test/polygon.txt") { |f| pol = Polygon.load(f) }
		assert_kind_of(Polygon, pol)
		assert(! pol.closed)

		pol2 = nil
		assert_nothing_raised { File.open("test/polygon1.txt") { |f| pol2 = Polygon.load(f) } }
		assert_kind_of(Polygon, pol2)
	end# }}}

	def test_inside# {{{
		pol = Polygon.new

		p = []
		@input.each_line do |l|
			p << Coord.load(l)
			pol << p.last
		end

		assert_raise(PolygonError) { pol.inside?(2,3) }
		pol.close

		#puts pol

		assert_equal(4, pol.size)
		assert(!pol.inside?(10, 10), "10,10 not inside")

		# test polygon corner
		p.each_index { |i| assert(pol.inside?(p[i].x, p[i].y), "p #{i} outside") }

		# some points
		assert(pol.inside?(2, 1))
		assert(pol.inside?(5, 2))
		assert(pol.inside?(3, 5))
		assert(pol.inside?(1, 3))

		# some more points
		assert(@pol2.inside?(175, 51))
		assert(@pol2.inside?(177, 78))
		assert(!@pol2.inside?(234, 71))
	end# }}}

	def test_find_next_edge# {{{
		p = Coord.new(220,226)
		assert_equal(13, @pol2.find_next_edge(p, Coord.new(1,0)))
		assert_equal(13, @pol2.find_next_edge(Coord.new(255,255), Coord.new(1,0)))
		assert_equal(15, @pol2.find_next_edge(Coord.new(255,285), Coord.new(1,0)))
		assert_equal(23, @pol2.find_next_edge(Coord.new(374,122), Coord.new(-1,0)))

		assert_equal(23, @pol2.find_next_edge(Coord.new(84,218), Coord.new(-1,0)))
		assert_equal(21, @pol2.find_next_edge(Coord.new(84,218), Coord.new(1,0)))
		assert_equal(0, @pol2.find_next_edge(Coord.new(84,218), Coord.new(0,-1)))
		assert_equal(22, @pol2.find_next_edge(Coord.new(84,218), Coord.new(0,1)))

		assert_equal(5, @pol2.find_next_edge(Coord.new(306,102), Coord.new(-1, 0)))

		assert_equal(14, @pol2.find_next_edge(Coord.new(379,281), Coord.new(0, -1)))
		assert_equal(15, @pol2.find_next_edge(Coord.new(379,281), Coord.new(1, 0)))
		assert_equal(16, @pol2.find_next_edge(Coord.new(379,281), Coord.new(0, 1)))
		assert_equal(17, @pol2.find_next_edge(Coord.new(379,281), Coord.new(-1, 0)))
	end# }}}

	def test_each_edge# {{{
		assert(@pol2.closed)
		n = 0
		se = @pol2[0]
		ee = @pol2[-1]
		@pol2.each_edge { |v1, v2| n +=1 }
		assert_equal(n, @pol2.size)

		pol = Polygon.new
		p = []
		@input.each_line do |l|
			p << Coord.load(l)
			pol << p.last
		end

		assert(!pol.closed)
		assert_equal(4, pol.size)
		n = 0
		first = nil
		last = nil
		pol.each_edge { |v1, v2|  
			n += 1
			first = v1 if ! first
			last = v2
		}
		assert_equal(3, n)
		assert_equal(first, pol[0])
		assert_equal(last, pol[-1])
	end# }}}

	def test_edge_dir# {{{
		assert_equal(:right, @pol2.edge_dir(0, 1))
		assert_equal(:up, @pol2.edge_dir(1, 2))
		assert_equal(:left, @pol2.edge_dir(5, 4))
		assert_equal(:down, @pol2.edge_dir(7, 8))
		assert_equal(:up, @pol2.edge_dir(19,20))

		assert_equal(:down, @pol2.edge_dir(0, -1))
	end# }}}

	def test_zoom# {{{
		p1 = @pol2[0]
		pol = @pol2.zoom(10)

		assert_equal(p1, pol[0])
		assert_not_same(p1, pol[0])
		assert_equal(@pol2.size, pol.size)
		assert_equal(@pol2.closed, pol.closed)

		assert_not_same(pol, @pol2)
	end# }}}

	def test_cut# {{{
		pol2 = nil
		File.open("test/polygon1.txt") { |f| pol2 = Polygon.load(f) }
		pol3 = pol2.dup
		#pol2.debug = true

		start_edge = 6
		end_edge = 2
		t6 = Polygon.new.load(StringIO.new(<<-FIN))# {{{
		Polygon:
		0 (17,5)
		1 (7,5)
		2 (7,14)
		3 (18,14)
		FIN
		# }}}
		
		# test exception raise for unclosed polygon
		assert_raise(PolygonError) { pol2.cut(t6, start_edge, end_edge) }

		pol2.close
		assert_equal(10, pol2.size)

		# simple crossing cut# {{{
		np1, np2 = pol2.cut(t6, start_edge, end_edge)
		# test distinct points for each 3 polygon: pol2, np1, np2
		assert_not_same_points(pol2, np1, np2)
		#print_pol(np1, np2.translate(1,1), pol3.close.translate(31, 0), t6.translate(30,0))

		assert(np1.closed)
		assert(np2.closed)

		assert_equal(8, np1.size)
		assert_equal(6, np2.size)

		assert(no_alligned_points?(np1), "aligned points np1") 
		assert(no_alligned_points?(np2), "aligned points np2") 
		# }}}

		# single edge tail# {{{
		# corner hit point starting edge 0 => edge 6 hiting corner 6
		p = Coord.new(pol2[0].x, pol2[6].y)
		motion = Coord.new(1, 0)

		start_edge = 0
		end_edge = pol2.find_next_edge(p, motion)

		tail = Polygon.new << p << Coord.new(pol2[end_edge].x, p.y)

		np1, np2 = pol2.cut(tail, start_edge, end_edge)

		assert_equal(6, np1.size)
		assert_equal(6, np2.size)
		assert(no_alligned_points?(np1), "aligned points np1") 
		assert(no_alligned_points?(np2), "aligned points np2") 
# }}}
		
		# some more test: single aligned cut between to verticaly aligned corner# {{{
		# we modify pol2 edge 2 
		pol2[2].x = pol2[6].x
		pol2[3].x = pol2[6].x

		# create a tail with some points of the polygon
		tail = Polygon.new << pol2[3].dup << pol2[6].dup
		start_edge = 2
		end_edge = 6
		np1, np2 = pol2.cut(tail, start_edge, end_edge)
		#print_pol(np1, np2.translate(1,0), pol3.close.translate(31, 0), tail.translate(30,0))

		assert(no_alligned_points?(np1), "aligned points np1") 
		assert(no_alligned_points?(np2), "aligned points np2") 
# }}}

		# same edge + corner# {{{
		tail = Polygon.new << pol2[6].dup << Coord.new(pol2[6].x / 2, pol2[6].y) <<
		                      Coord.new(pol2[7].x / 2, pol2[7].y) << pol2[7].dup
		start_edge = 6
		end_edge = 6
		np1, np2 = pol2.cut(tail, start_edge, end_edge)
		#print_pol(np1,np2.translate(1,1))
		assert_not_same_points(pol2, np1, np2)
		assert(no_alligned_points?(np1), "aligned points np1") 
		assert(no_alligned_points?(np2), "aligned points np2") 

		assert_equal(10, np1.size)
		assert_equal(4, np2.size)
# }}}
		
		# same edge + no corner# {{{
		tail = Polygon.new << Coord.new(pol2[6].x, pol2[6].y - 1) << Coord.new(pol2[6].x / 2, pol2[6].y - 1) <<
		                      Coord.new(pol2[7].x / 2, pol2[7].y + 1) << Coord.new(pol2[7].x, pol2[7].y + 1)
		start_edge = 6
		end_edge = 6
		np1, np2 = pol2.cut(tail, start_edge, end_edge)
		#print_pol(np1)#,np2.translate(3,0))
		assert_not_same_points(pol2, np1, np2)
		assert(no_alligned_points?(np1), "aligned points np1") 
		assert(no_alligned_points?(np2), "aligned points np2") 
		assert_equal(14, np1.size)
		assert_equal(4, np2.size)
# }}}
	end# }}}

	def no_alligned_points?(pol)# {{{
		pp = nil
		r = true
		pol.each_edge { |v1, v2|
			#puts "#{pp} #{v1} #{v2}"

			if ! pp
				pp = v1
				next
			end

			if pp.x == v2.x && v2.x == v1.x or pp.y == v2.y && v2.y == v1.y
				r = false
				break
			end
			pp = v1
		}

		r
	end# }}}

end
