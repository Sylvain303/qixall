# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# Monster class - handle basic monster behavior
#

class Monster#{{{
  def initialize(window)
    @window = window
    @image = Gosu::Image.new(@window, MONSTER_IMG, false)
    @h = @image.height
    @w = @image.width

    @factor = 0.5
    @h *= @factor
    @w *= @factor
    mid = Coord.new(@w / 2, @h / 2)
    puts "monster image @w=#{@w}, @h1=#{@h}"

    # velocity
    @vel = Coord.new(1, 1)
    @angle = 0.0
    @rotate = 1.0

    @border_area = @window.playground.area
    @min, @max = @border_area.corners
    @me = Coord.new((@min.x + @max.x) / 2, (@min.y + @max.y) / 2)

    # a surrounding bounding box
    @b = Box.new(@window, @me - mid, @me + mid)
  end

  attr_reader :me
  attr_accessor :factor

  def start(area)
    @area = area
    @start = @area[0]
    @x, @y = @start.x + @image.width, @start.y + @image.height
    @speed = 4
    # @angle = rand(360)
  end

  def draw
    @image.draw_rot(@me.x, @me.y, ZOrder::Monster,
                    @angle, 0.5, 0.5, @factor, @factor)
    @window.draw_point(@me)
    # draw bounding box
    @b.draw
  end

  def move
    @me.x += @vel.x
    @me.y += @vel.y
    @b.move_by(@vel)
    @angle += @rotate
    if @angle > 360.0
      @angle = 0.0
    end
    if @angle < 0.0
      @angle = 360.0
    end

    edge = @border_area.find_nearest_edge(@me.x, @me.y)
    # @border_area.highlight = edge

    v1, v2 = @border_area.get_edge(edge)

    # collide with edge
    if v1.x == v2.x # V
      d = (@me.x - v1.x).abs
      dir = :vertical
    else # H
      d = (@me.y - v1.y).abs
      dir = :horizontal
    end

    if d < @h / 2
      # collision
      if dir == :vertical
        velsign = @vel.x < 0 ? 1 : -1
        @me.x = v1.x + (@w / 2 * velsign)
        @vel.x = - @vel.x
      else
        velsign = @vel.y < 0 ? 1 : -1
        @me.y = v1.y + (@h / 2 * velsign)
        @vel.y = - @vel.y
      end
    end

    self
  end
end#}}}
