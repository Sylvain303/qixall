# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# class Area: extends Polygon offering graphical rendering and games related
# methods
#
# methods related to interaction with player and monster should be here.


# local code
require 'polygon'
require 'line'

class Area < Polygon #{{{
  def initialize(window, points=nil)#{{{
    @window = window
    @boxes = []
    super(points)
    @highlight = nil
    @color =  0xFFFF00FF

    # store the rmagick fill picture
    @fill_image = nil
    # do or dont fill the area
    @fill = true
  end#}}}
  attr_accessor :highlight, :color, :fill
  attr_reader :points

  def last=(p)#{{{
    @points[-1] = p
  end#}}}

  def last#{{{
    @points[-1]
  end#}}}

  def draw#{{{
    # draw when only one single point
    # each_edge_with_index will iterate with 2 or more points
    if @points.size == 1
      @window.draw_point(@points[0])
      return
    end

    each_edge_with_index do |v1, v2, i1, i2|
      @window.draw_point(v1)
      @window.draw_point(v2)

      if i2 != 0 or @closed
        l = Line.new(@window, v1, v2)
        l.color = @color
        if @highlight && @highlight == i1
          l.color = 0xFFFF0000
        end
        l.draw
      end
    end

    if closed and @fill
      # fill with rmagick
      if @fill_image.nil?
        @fill_image = create_polygon(self)
      end
      @fill_image.draw(@min.x, @min.y, ZOrder::Polygon)
    end
  end#}}}

  # edge_out(i1, i2) return the symbol of the direction which let the player go inside the area#{{{
  # out mean: near the monster, which is in fact inside the area
  def edge_out(i1, i2)
    d = @points[i1] - @points[i2]
    if d.x == 0 # V edge
      if d.y < 0 # downward
        pt = Coord.new(@points[i1].x + 1, @points[i1].y + 1)
      else
        pt = Coord.new(@points[i1].x + 1, @points[i1].y - 1)
      end
      if inside?(pt.x, pt.y)
        return :right
      else
        return :left
      end
    else
      # H edge
      if d.x < 0 # rightward
        pt = Coord.new(@points[i1].x + 1, @points[i1].y + 1)
      else
        pt = Coord.new(@points[i1].x - 1, @points[i1].y + 1)
      end
      if inside?(pt.x, pt.y)
        return :down
      else
        return :up
      end
    end
  end#}}}

  # leave(old, other) returns the new index, leaving old based on the other corner #{{{
  def leave(old, other)
    # 3, 2 => 0 or 4 if size > 4     0-----------1
    # 2, 3 => 1                      |           |
    # 3, 0 => 2                      |           |
    # 0, 3 => 1                      |           |
    # 0, 1 => 3                      3-----------2

    p = prev_corner(old)
    n = next_corner(old)

    case other
    when p
      n
    when n
      p
    else
      raise "Area#leave(#{old}, #{other}) p=#{p} n=#{n}"
    end
  end#}}}

  # edge_leaving_dir(corner, other) given corner and other, return the direction of the leaving {{{
  # edge from the corner to other.
  def edge_leaving_dir(corner, other)
    c, o = @points[corner], @points[other]
    l = o - c
    case
    when (l.x == 0 and l.y > 0)
      return :down
    when (l.x == 0 and l.y < 0)
      return :up
    when (l.y == 0 and l.x > 0)
      return :right
    when (l.y == 0 and l.x < 0)
      return :left
    end
  end#}}}

  # rentrant_corner?(corner) eval if the corner allow out or not {{{
  def rentrant_corner?(corner)
    # an edge is numbered by its corner and the next in its polygon's coord
    # list.
    # A corner is rentrant if its out direction is the same as the previous edge
    # leaving direction.
    #
    # 0:
    # 1:       4--- 5
    # 2:       |    |
    # 3:       |    |
    # 4:       |    |
    # 5:       |    |
    # 6:  2--- 3    6--- 7
    # 7:  |              |
    # 8:  |              |
    # 9:  |              |
    #10:  |              |
    #11:  1----0    9----8
    #12:       |    |
    #13:       |    |
    #14:       |    |
    #15:       |    |
    #16:      11----0
    p, n = prev_corner(corner), next_corner(corner)
    dir_p, dir_out = edge_leaving_dir(corner, p), edge_out(corner, n)
    return dir_p == dir_out
  end#}}}

  # merge()
  def merge(area, start_edge, end_edge)
  end

  def load(iostream)#{{{#{{{
    empty!
    super(iostream)
    close
  end#}}}#}}}

  def read_file(filename)#{{{
    File.open(filename) {|f| self.load(f) }
    self
  end#}}}

  def empty!#{{{
    @points.clear
    @closed = false
    self
  end#}}}

  # corners() return the 2 coord top left and bottom right of the current area#{{{
  # see also: Polygon#find_min_max(), which will return the same result, only on
  # a box polygon thought.
  def corners
     tc = nil
     bc = nil
     @points.each do |p|
       tc = p if ! tc or tc.x > p.x or tc.y > p.y
       bc = p if ! bc or bc.x < p.x or bc.y < p.y
     end
     return tc, bc
  end#}}}

  def create_polygon(poly)#{{{
    min, max = poly.find_min_max()
    p = poly.dup.translate(-min.x, -min.y)

    w, h = max.x - min.x,  max.y - min.y

    #puts "min=#{min}, max=#{max} Magick::Image.new(#{w}, #{h})"
    #p.to_a.each_with_index {|c, i|
    #  puts "#{i}: #{c}"
    #}

    img = Magick::Image.new(w + @window.epais * 2, h + @window.epais * 2) {
      self.background_color = "transparent"
    }

    gc = Magick::Draw.new

    gc.fill_opacity(0)
    gc.fill('blue')

    gc.polyline(*p.to_a)

    gc.draw(img)

    image = Gosu::Image.new(img)

    return image
  end#}}}
end#}}}

# class Box is a simplier Polygon of 4 coord, defined by its top_left
# and bottom_right corner
class Box#{{{
  # p1 ------------------------ p2
  #  |                           |
  #  |                           |
  #  |                           |
  #  |                           |
  #  |                           |
  #  |                           |
  #  |                           |
  # p4 ------------------------ p3
  def initialize(w, p1, p3)
    @window = w
    @p1, @p3 = p1.dup, p3.dup
    d = @p3 - @p1

    if d.x < 0
      @p1.x, @p3.x = @p3.x, @p1.x
      d.x = - d.x
    end

    if d.y < 0
      @p1.y, @p3.y = @p3.y, @p1.y
      d.y = - d.y
    end

    raise "invalid box #@p1 #@p3" if @p1.x - @p3.x == 0 or @p1.y - @p3.y == 0

    @p2 = Coord.new(@p3.x, @p1.y)
    @p4 = Coord.new(@p1.x, @p3.y)
  end

  def move_by(coord)
    @p1.x += coord.x
    @p1.y += coord.y
    @p2.x += coord.x
    @p2.y += coord.y
    @p3.x += coord.x
    @p3.y += coord.y
    @p4.x += coord.x
    @p4.y += coord.y
  end

  def to_s
    "#{@p1}x#{@p2}"
  end

  def draw
    @window.draw_point(@p1)
    @window.draw_point(@p2)
    @window.draw_point(@p3)
    @window.draw_point(@p4)

    Line.new(@window, @p1, @p2).draw
    Line.new(@window, @p2, @p3).draw
    Line.new(@window, @p3, @p4).draw
    Line.new(@window, @p4, @p1).draw
  end
end#}}}

