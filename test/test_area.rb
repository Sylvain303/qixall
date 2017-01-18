# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:

require 'test/unit'
require 'stringio'

$:.push(File.expand_path(File.dirname(__FILE__) + '/..'))
require 'area'

class TC_Area < Test::Unit::TestCase
	def setup
		@area = Area.new(nil)
		@area.read_file("./area0.txt")
	end

	def test_load
		area = Area.new(nil)
		assert_raise(RuntimeError) { 	area.read_file("./unclosed_area.txt") }
		assert(! area.closed)
	end
	def test_edge_out#{{{
		assert_equal(:right, @area.edge_out(1, 2))
		assert_equal(:down, @area.edge_out(0, 1))
		assert_equal(:right, @area.edge_out(0, 23))
		assert_equal(:right, @area.edge_out(23, 0))
		assert_equal(:left, @area.edge_out(21, 22))
		assert_equal(:up, @area.edge_out(20, 21))
	end#}}}

	def test_next_prev#{{{
		assert_equal(24, @area.size)

		assert_equal(0, @area.next_corner(23))
		assert_equal(1, @area.next_corner(0))

		assert_equal(1, @area.prev_corner(2))
		assert_equal(23, @area.prev_corner(0))
	end#}}}

	def test_leave#{{{
		# leave use prev_corner et next_corner
		assert_equal(0, @area.leave(1, 2))
		assert_equal(2, @area.leave(1, 0))
		assert_equal(1, @area.leave(0, 23))
		assert_equal(23, @area.leave(0, 1))
	end#}}}
end
