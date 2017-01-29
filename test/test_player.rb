# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:

require 'test/unit'

require_relative 'mock_window'

$:.push(File.expand_path(File.dirname(__FILE__) + '/..'))
require 'player'
require 'playground'

## reopen class to add a reader
#someinstance.class.class_eval { attr_reader :root_id }

class TC_Player < Test::Unit::TestCase
  class PlayerT < Player
    # add for testing
    attr_accessor :draw_angle, :prev, :next, :liberty, :zone, :me
    attr_accessor :on_corner, :area, :out, :tail, :tail_start, :tail_start_edge
    attr_accessor :delta_edge, :next_dir, :current_dir, :motion
  end

  def _init_player
    p = PlayerT.new(@fake_window)
    @playground = Playground.new(@fake_window)
    p.start(@playground, 0, 3)
    return p
  end

  def _add_tail(p, fname)
    p.create_tail
    # load a tail
    _load_tail(p.tail, fname)
    # adjust player
    p.tail_start = p.tail[0]

    p.zone = :out
    # last edge dir…
		p.next_dir = :down

    # move player at end of tail
    p.me = p.tail[-1]
  end

	def setup
    @fake_window = MockWindow.new
    @liberty = {
      :left  => true,
      :right => true,
      :up    => true,
      :down  => true,
    }
	end

  def test_initialize
    p = PlayerT.new(@fake_window)
    assert_kind_of(Player, p)
  end

  def _load_tail(tail_ref, fname)
    tail_ref.empty!
    File.open(fname) {|f| 
      # bypass derived method of class Area and call parent method directly
      Polygon.instance_method(:load).bind(tail_ref).call(f)
    }
    # so the polygon may be unclosed
  end

  def test_start
    p = PlayerT.new(@fake_window)
    playground = Playground.new(@fake_window)
    # between 0 and 3 (left edge)
    p.start(playground, 0, 3)

    assert_equal(:in, p.zone)
    assert_equal(:right, p.draw_angle)
    assert_equal(0, p.prev)
    assert_equal(3, p.next)

    l = @liberty.merge({:right => false, :left => false})
    assert_equal(l, p.liberty)
    assert_equal([:right], p.out)
  end

  def test_set_player_liberty
    p = _init_player

    # :in
    p.zone = :in
    p.set_player_liberty

    # between 0 and 3 (left edge)
    l = @liberty.merge({:left => false, :right => false})
    assert_equal(l, p.liberty)
    assert_equal([:right] , p.out)

    # top edge
    p.start(@playground, 0, 1)
    l = @liberty.merge({:up => false, :down => false})
    assert_equal(l, p.liberty)
    assert_equal([:down] , p.out)

    # on_corner (top left corner)
    p.on_corner = 0
    p.prev = p.area.prev_corner(p.on_corner)
    p.next = p.area.next_corner(p.on_corner)
    assert_equal(3, p.prev)
    assert_equal(1, p.next)
    p.set_player_liberty

    l = @liberty.merge({:up => false, :left => false})
    assert_equal(l, p.liberty)

    # savoie
    @playground.area.read_file('polygon_savoie.txt')
    p.start(@playground, 0, 1)
    l = @liberty.merge({:up => false, :down => false})
    assert_equal(l, p.liberty)

    p.on_corner = 0
    p.prev = p.area.prev_corner(p.on_corner)
    p.next = p.area.next_corner(p.on_corner)
    p.set_player_liberty

    l = @liberty.merge({:up => false, :right => false})
    assert_equal(l, p.liberty)
    assert_equal([:right, :up] , p.out)

    # testing out, restart on playground square
    p = _init_player
    _add_tail(p, 'polygon_tail1.txt')

		assert p.hit_tail?

    assert_nil p.delta_edge
  end

  def test_create_tail
    p = _init_player
    p.create_tail
    assert_equal(p.me, p.tail[0])
    assert_equal(1, p.tail.size)
    assert p.area.on_edge(p.tail_start_edge, p.me.x, p.me.y)
  end

  def test_hit_tail?  
    p = _init_player
    p.create_tail
    # load a tail
    _load_tail(p.tail, 'polygon_tail1.txt')
    # adjust player
    p.tail_start = p.tail[0]
    assert p.area.on_edge(p.tail_start_edge,
                          p.tail_start.x,
                          p.tail_start.y)

    p.zone = :out
		p.next_dir = :down

    # move player at end of tail
    p.me = p.tail[-1]
    p.set_player_liberty

		assert p.hit_tail?

    # rewind back a little
    p.me.y -= 20
		assert ! p.hit_tail?
  end
end

