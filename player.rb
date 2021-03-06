# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# encoding: utf-8
#
# class Player, handling player behavior
#

require 'coord'

class Player
  def initialize(window)#{{{
    @window = window
    @image = Gosu::Image.new(@window, "media/RubyGem.png", false)
    # store the player position
    @me = Coord.new(0, 0)
    # will store movement key in @motion
    @current_dir = @next_dir = :none
    @draw_angle = :up
    # velocity
    @speed = 3
    # preset motion, corresponding to available player's movement.
    # used as increment in #move()
    @motion = {
      :none  => Coord.new(0, 0),
      :left  => Coord.new(-@speed, 0),
      :right => Coord.new(@speed, 0),
      :up    => Coord.new(0, -@speed),
      :down  => Coord.new(0, @speed),
    }

    # easy compute Hash
    @opposit_dir = {
      :left  => :right,
      :right => :left,
      :up    => :down,
      :down  => :up,
    }

    # Is the player allowed to go in this direction?
    # will be checked in change_dir() and set in set_player_liberty
    @liberty = {
      :left  => true,
      :right => true,
      :up    => true,
      :down  => true,
    }
    # allowed out direction if we are :in
    @out = []

    # Area instance which will hold the trace when the player is outside
    @tail = nil
    # 3 states variable: :in, safe from Monster, or :out making a trace
    # :go_out, transitive state, will become :out
    @zone = :in

    # index of the Coord in @playground.area if the player is on a corner or
    # nil.
    @on_corner = nil

    # @area will hold an Area object representing the :in where the player can
    # move safely, set by the GameWindow when the player starts, aka the
    # playground.
    @area = nil

    # during move, record that we were stoped by some constraint
    @stoped = false
  end#}}}

  attr_reader :current_dir, :next_dir, :zone

  def start(playground, p1, p2)#{{{
    @zone = :in
    @playground = playground
    # shortcut to the area
    @area = playground.area

    # p1 and p2 are two consecutive points index on @area
    @prev = p1
    @next = p2

    # @delta_edge is the delta between the 2 corners on @area when you are :in
    @delta_edge = @area[@next] - @area[@prev]

    # start player coordinate, between p1 and p2
    if @delta_edge.x != 0 && @delta_edge.y == 0
      # H
      @me = Coord.new(@area[@prev].x + @delta_edge.x / 2, @area[@prev].y)
      if @area.inside?(@me.x, @me.y - 1)
        @draw_angle = :up
      else
        @draw_angle = :down
      end
    elsif @delta_edge.x == 0  && @delta_edge.y != 0
      # V
      @me = Coord.new(@area[@prev].x, @area[@prev].y + @delta_edge.y / 2)
      if @area.inside?(@me.x + 1, @me.y)
        @draw_angle = :right
      else
        @draw_angle = :left
      end
    else
      raise "p1=#{p1} p2=#{p2} #{@area[@prev]} #{@area[@next]} @delta_edge=#{@delta_edge}"
    end

    @on_corner = nil
    @action_button = false
    @current_dir = @next_dir = :none

    # puts "#{@me} delta_edge=#{@delta_edge} p1=#{p1} p2=#{p2} #{@area[@prev]} #{@area[@next]}"

    set_player_liberty
  end#}}}

  def set_player_liberty#{{{
    if @zone == :in
      # reset
      @liberty.each_key {|k| @liberty[k] = true }

      @delta_edge = @area[@next] - @area[@prev]
      @x_min = @delta_edge.x < 0 ? @area[@next].x : @area[@prev].x
      @y_min = @delta_edge.y < 0 ? @area[@next].y : @area[@prev].y
      @x_max = @delta_edge.x < 0 ? @area[@prev].x : @area[@next].x
      @y_max = @delta_edge.y < 0 ? @area[@prev].y : @area[@next].y

      # test where the player can go :out
      if ! @on_corner
        out_dir = @area.edge_out(@prev, @next)
        # needs button to goes out see change_dir()
        @liberty[out_dir] = false
        @liberty[@opposit_dir[out_dir]] = false
        @out = [ out_dir ]
      else
        # only 2 directions on corner, go on edge
        dir_n = @area.edge_leaving_dir(@on_corner, @next)
        dir_p = @area.edge_leaving_dir(@on_corner, @prev)

        @liberty[@opposit_dir[dir_n]] = false
        @liberty[@opposit_dir[dir_p]] = false

        if @area.rentrant_corner?(@on_corner)
          # you can't get out from a rentrant corner
          @out = []
        else
          @out = [@opposit_dir[dir_n], @opposit_dir[dir_p]]
        end
      end
    else
      # out
      @delta_edge = nil
      @x_min = @y_min = @x_max = @y_max = nil

    end

    # puts "x_min=#{@x_min}"
    # puts "x_max=#{@x_max}"
    # puts "y_min=#{@y_min}"
    # puts "y_max=#{@y_max}"
  end#}}}

  def action(button)#{{{
    case button
    when :down
      @action_button = true
      @rewind = false
    when :up
      if @action_button and @tail
        @rewind = true
      end
      @action_button = false
    end
  end#}}}

  def horizontal?(dir)#{{{
    dir == :left or dir == :right
  end#}}}

  def vertical?(dir)#{{{
    dir == :up or dir == :down
  end#}}}

  # change_dir(new_dir) : called by Window.update, at each tick {{{
  # change @next_dir if authorized.
  # new_dir is a symbol :up, :down, :left, :right
  #
  def change_dir(new_dir)
    case @zone
    when :in
      #puts ":in delta_edge=#{@delta_edge} new_dir=#{new_dir} action_button=#{@action_button} @on_corner=#{@on_corner}"
      if ! @action_button and (
         ((new_dir == :up    or new_dir == :down) && @delta_edge.y != 0) or
         ((new_dir == :right or new_dir == :left) && @delta_edge.x != 0) )

        # player has liberty to move on the line
        # if we are on corner we have 2 liberty:
        #   @delta_edge.x && @delta_edge.y != 0
        #puts "player has liberty"
        @next_dir = new_dir
      elsif @action_button
        # test if the player can go :out in the requested direction
        if ! @on_corner && @area.edge_out(@prev, @next) == new_dir
          @next_dir = new_dir
          @zone = :go_out
        elsif @on_corner
          # geting out from a corner, you can't from inside corner
          out = [ @area.edge_out(@prev, @on_corner), @area.edge_out(@on_corner, @next) ]
          # just DRY
          out.each_with_index {|out_dir, i|
            case out_dir
            when :up
              px, py = @me.x, (@me.y - 1)
            when :down
              px, py = @me.x, (@me.y + 1)
            when :left
              px, py = (@me.x - 1), @me.y
            when :right
              px, py = (@me.x + 1), @me.y
            end

            # on_edge() detect inside corner
            if new_dir == out_dir and ! @area.on_edge( i == 0 ? @on_corner : @prev , px, py)
              @next_dir = new_dir
              @zone = :go_out
              # we can leave the loop
              break
            end
          }
          end
        end
    when :out
      @add_point = false
      if ! @action_button
        @rewind = true
      else
        # out and going…

        # puts "new_dir=#{new_dir} @current_dir=#{@current_dir} @opposit_dir[@current_dir]=#{@opposit_dir[@current_dir]}"
        if (  (vertical?(@current_dir) and vertical?(new_dir)) or
            (horizontal?(@current_dir) and horizontal?(new_dir)) )

          # same dir, ok no more point
          @next_dir = new_dir
        else
          # we changed the dir, so we add a new point
          @next_dir = new_dir
          @add_point = true
        end
      end

      if hit_tail?
        # we are going to reach our tail and we need to stop
        stop
      end
      #if @next_dir != :none
      #  highlight_edge
      #end
    else
      puts "skiped: unknown zone #{@zone}"
    end
  end#}}}

  def rewind#{{{
    @rewind = true

    if @tail.size == 1
      last = @tail[0]
    else
      last = @tail[-2]
    end

    # go back on trace
    d = nil
    2.times do
      d = @me - last
      if d.is?(0, 0)
        @tail.pop
      else
        break
      end

      if @tail.size == 0
        @zone = :in
        remove_tail
        set_player_liberty
        return
      else
        last = @tail[-1]
      end
    end

    case
    when (d.x == 0 and d.y > 0)
      rmove = :up
    when (d.x == 0 and d.y < 0)
      rmove = :down
    when (d.y == 0 and d.x < 0)
      rmove = :right
    when (d.y == 0 and d.x > 0)
      rmove = :left
    when (d.y == 0 and d.x == 0)
      # we are on the corner
      # TODO: do something
    end

    @me.x += @motion[rmove].x
    @me.y += @motion[rmove].y

    if @tail.size == 0
      @zone = :in
      remove_tail
    else
      if last == @me
        @tail.pop
      end

      @tail.last = @me.dup
    end

    set_player_liberty
  end#}}}

  # create_tail : before the move, create data sturcture #{{{
  # steps:
  #  - change_dir set @zone at :go_out
  #  - move will call check_move
  #  - check_move will call create_tail
  #  - increase_move will be called after
  def create_tail
    puts "create_tail"
    @rewind = false
    @tail = Area.new(@window)
    @tail_start = @me.dup
    @tail_start_edge = @area.find_nearest_edge(@me.x, @me.y)
    @tail << @tail_start
    @add_point = true
    puts "me=#{@me} tail_start_edge=#{@tail_start_edge}"
  end#}}}

  def remove_tail#{{{
    puts "remove_tail"
    @tail = nil
    @tail_start = nil
    @tail_start_edge = nil
    @add_point = false
    @rewind = false
  end#}}}

  # so we were :out and finaly reach some other edge
  def close_area#{{{
    # rewinding or moving back to the begining
    if @rewind or @tail.size == 2 and @me == @tail[0]
      remove_tail
      return
    end

    edge = @area.find_nearest_edge(@me.x, @me.y)
    @tail_end = @me.dup
    v1, v2 = @area.get_edge(edge)
    if v1.x == v2.x # V
      @me.x = @tail_end.x = v1.x
    else
      # H
      @me.y = @tail_end.y = v1.y
    end

    @tail << @tail_end if @tail[-1] != @tail_end

    begin
      pol1, pol2 = @area.cut(@tail, @tail_start_edge, edge)
    rescue PolygonError, RuntimeError => e
      puts "\e[41mError\e[0m e=#{e}"
      puts "@tail_end=#{@tail_end} @hit_area=#{@hit_area} @me=#{@me} edge=#{edge}"
      puts "v1=#{v1}, v2=#{v2}"
      puts @tail.to_s
      return
    end

    puts @tail.to_s
    puts "pol1\n", pol1.to_s
    puts "pol2\n", pol2.to_s

    if pol1.inside?(@window.monster.me.x, @window.monster.me.y)
      new_area = pol1
      to_fill = pol2
    else
      new_area = pol2
      to_fill = pol1
    end

    new_edge = new_area.find_nearest_edge(@me.x, @me.y)

    @on_corner = new_edge
    @prev = new_area.prev_corner(@on_corner)
    @next = new_area.next_corner(@on_corner)

    @area.replace!(new_area)
    @playground.fill_playground(to_fill)
    remove_tail
  end#}}}

  def stop#{{{
    @disabled_dir = @current_dir
    puts "STOP player, you can't move more"
    @current_dir = @next_dir = :none
    @stoped = true
  end#}}}

  # move()#{{{
  #
  # player's behavior
  #
  # The action button Player.action(:down) allow the player to go :out.
  # If you release the button the player will rewind on its tail.
  # The states of the action button is saved in @action_button = true.
  # During the update loop in GameWindow.update() player direction buttons are
  # checked:
  #  => calling the related Player.change_dir()
  #     the goal of change_dir() is to validate the change of direction
  #     depending on the context.
  # Move algorithm:
  #  1. moving on the @area :in, player is allowed to move only on the polygon
  #  2. geting ouside :out and creating the @tail
  #
  #  check_move? -> constrains the move if any rules apply
  #  increase_move if allowed -> the player position is increased
  #  collide -> after the move, check if we hit something
  #  @current_dir is updated with @next_dir (previously set in change_dir())
  #  @next_dir is reset (needed to keep holding the button)
  #  If :out and some change in the direction, add a point to the tail.
  def move
    if check_move?
      increase_move
    end
    collide

    # user must keep holding the direction key down to continue moving
    @current_dir = @next_dir
    @next_dir = :none

    if @tail
      if @add_point
        @tail << @me.dup if @tail.last != @me
        @add_point = false
      else
        # update last point of the tail with the player position
        # when you come back on the tail you can reach the last point
        if @tail.size > 2 and @tail[-2] == @me
          # in this case, we change the @current_dir so a new point will be
          # added.
          @current_dir = @tail.edge_dir(start_edge=-3, end_edge=-2)
          @tail.pop
        end
        @tail.last = @me.dup
      end
    end
  end#}}}

  def check_move? #{{{
    if @rewind
      return true
    end

    if @zone == :go_out
      @zone = :out
      create_tail
    end

    if @next_dir == :none
      return false
    end

    # we have some constrained move (tail collide or :in constraint)

    true
  end#}}}

  def increase_move#{{{
    if @rewind
      rewind
    else
      @me.x += @motion[@next_dir].x
      @me.y += @motion[@next_dir].y

      @draw_angle = @next_dir
    end
  end#}}}

  # collide() search what the player will collide if he's continue going#{{{
  # in the same direction.
  def collide
    # overflow
    if @me.x > @window.screen_w or
      @me.y > @window.screen_h or
      @me.x < 0 or @me.y < 0
      raise "player HITs window's limit: #{@me}"
    end

    case @zone
    when :in
      # correcting increment too far
      @me.x = @x_min if @me.x < @x_min
      @me.x = @x_max if @me.x > @x_max
      @me.y = @y_min if @me.y < @y_min
      @me.y = @y_max if @me.y > @y_max

      # we are moving on a edge between 2 points on the @area
      if @on_corner
        # the player leave the corner, @on_corner eval true
        if ! @area[@on_corner].is?(@me.x, @me.y)
          #puts "leaving corner #{@on_corner}"
          # so we have left @on_corner and we are going to @prev or @next
          if @area[@prev].x - @me.x != 0 && @area[@prev].y - @me.y != 0
            #puts "leaving prev = #{@prev}"
            @prev = @on_corner
          elsif @area[@next].x - @me.x != 0 && @area[@next].y - @me.y != 0
            #puts "leaving next = #{@next}"
            @next = @on_corner
          else
            # it seems we are not on @prev nor on @next
            # this happens when we have 3 points lined up
            raise "on_corner=#{@on_corner}? cur=#{@me} prev=#{@area[@prev]} next=#{@area[@next]}"
          end
          @on_corner = nil
        end
      else
        # we have reached an other corner
        if @area[@prev].is?(@me.x, @me.y)
          @on_corner = @prev
          @prev = @area.leave(@prev, @next)
        elsif @area[@next].is?(@me.x, @me.y)
          @on_corner = @next
          @next = @area.leave(@next, @prev)
        end
      end
    when :out
      # player must stay inside the area
      # if we are no more inside, this mean that we are now reaching
      # the border
      inside = @area.inside?(@me.x, @me.y, match_edge = false)
      if ! inside
        close_area
        @zone = :in
        @current_dir = @next_dir = :none
      end
    else
      raise "unknown zone #{@zone}"
    end

    set_player_liberty
  end#}}}

  # hit_tail?(distance=4) : only call when outside and a tail exists.
  def hit_tail?(distance=4)
    if @next_dir == :none
      return false
    end

    edge = @tail.find_next_edge(@me, @motion[@next_dir])
    if edge
      if vertical?(@next_dir)
        d_tail = (@tail[edge].y - @me.y).abs
      else
        d_tail = (@tail[edge].x - @me.x).abs
      end
      puts "hit_tail? #{edge} @next_dir=#{@next_dir} d_tail=#{d_tail} #{@tail[edge]} #{@me}"

      if d_tail <= distance
        return true
      end
    end

    return false
  end

  # highlight_edge() find @area or @tail that we could hit in our direction#{{{
  # Usage: if @next_dir != :none and @zone == :out call the method.
  # Example un change_dir() or collide() (not sure)
  def highlight_edge
    hit_area = @area.find_next_edge(@me, @motion[@next_dir])
    hit_tail = @tail.find_next_edge(@me, @motion[@next_dir])

    puts "area hit_edge=#{hit_area} tail hit_edge=#{hit_tail}"

    if hit_tail
      if @motion[@next_dir].x != 0
        d_area = (@area[hit_area].x - @me.x).abs
        d_tail = (@tail[hit_tail].x - @me.x).abs
      else
        d_area = (@area[hit_area].y - @me.y).abs
        d_tail = (@tail[hit_tail].y - @me.y).abs
      end

      puts "d_tail=#{d_tail}"

      if d_tail <= 0
        # stop
        puts "tail hit!"
      end

      if d_tail < d_area
        ref = @tail
        hit = hit_tail
      else
        ref = @area
        hit = hit_area
      end
    else
      ref = @area
      hit = hit_area
    end

    # comment it to disable highlighting
    ref.highlight = hit
  end#}}}

  def draw#{{{
    @image.draw_rot(@me.x, @me.y, ZOrder::Player, ANGLE[@draw_angle])
    @tail.draw if @tail
  end#}}}

  def puts_info#{{{
    puts "on_corner=#{@on_corner} @delta_edge=#{@delta_edge} cur=#{@me} prev=#{@prev}#{@area[@prev]} next=#{@next}#{@area[@next]}"
  end#}}}
end
