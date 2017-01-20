# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
#
# vimF12: ruby test_coord.rb

require 'test/unit'
require 'stringio'

$:.push(File.expand_path(File.dirname(__FILE__) + '/..'))
require 'coord'

class TC_Coord < Test::Unit::TestCase

  def test_initialize
    c = Coord.new(22, 33)
    assert_equal(22, c.x)
    assert_equal(33, c.y)
  end

	def test_load
    # pass a string
		c = Coord.load("0 (17,5)")
    assert_equal(17, c.x)
    assert_equal(5, c.y)
	end
end
