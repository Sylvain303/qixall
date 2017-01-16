# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# Game editor only
#

require 'rubygems'
require 'bundler/setup'

# local code
$:.push('.')
require 'gosu'
require 'coord'
require 'polygon'
require 'area'
require 'free_line'
require 'playground'
require 'monster'
require 'grid'

# debug
require 'pry'
require 'pry-nav'

module ZOrder
  Background, Monster, Grid, Lines, UI, Mouse = *0..20
end

# Config# {{{
LINEW = 3  # thickness
GRID = 10
ANGLE = {
  :up    => 180.0,
  :down  => 0.0,
  :left  => 90.0,
  :right => 270.0,
}

MONSTER_IMG = "media/img/monster_round_fire.png"
# }}}



class GameWindow < Gosu::Window#{{{
  def initialize#{{{
    @screen_w = 640
    @screen_h = 480
    super(@screen_w, @screen_h, false, 10)
    self.caption = "Qixall editor"

    @epais = LINEW

    @playground = Playground.new(self)
    # @grid is unsing @window.playground at runtime for corners
    @grid = Grid.new(self, GRID)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @cursor = Gosu::Image.new(self, "media/Cursor.png", false)

    @area_click = Area.new(self)
    @area_last_loaded = {}

    @tool = :none
    @all_tools = [ :none, :area, :free_line, :multi_line ]

    # free lines
    @flines = []
    @current_line = nil
    @active_lines = []
  end#}}}

  attr_reader :epais, :grid, :screen_h, :screen_w, :playground, :monster
  attr_accessor :tail

  def update#{{{
  end#}}}

  def draw_point(p)#{{{
    green = 0xFF00FF00
    off = 2
    draw_quad(p.x - off, p.y - off, green,
              p.x + off, p.y - off, green,
              p.x - off, p.y + off, green,
              p.x + off, p.y + off, green,
              ZOrder::UI, mode=:default)
  end#}}}

  def draw#{{{
    #@monster.draw
    @playground.draw
    @cursor.draw(mouse_x, mouse_y, ZOrder::Mouse)

    # view port
    @font.draw("mouse pos: #{mouse_x}, #{mouse_y}", 10, 10,
               ZOrder::UI, 1.0, 1.0, 0xffffff00)
    @font.draw("grid: #{@grid}", 470, 10,
               ZOrder::UI, 1.0, 1.0, 0xffffff00)
    @font.draw("area: #{@playground.area.size}", 230, 10,
               ZOrder::UI, 1.0, 1.0, 0xffffff00)
    # 2nd line
    @font.draw("clic: #{@click}", 10, 10 + 1*15,
               ZOrder::UI, 1.0, 1.0, 0xffffff00)
    @font.draw("tool: #{@tool}", 230, 25,
               ZOrder::UI, 1.0, 1.0, 0xffffff00)

    # the area
    @area_click.draw if @area_click

    # the grid
    @grid.draw

    # free_line
    @flines.each {|l| l.draw }
    @active_lines.each {|fl| fl.each {|l| l.draw } }

    # draw in progess line
    if @current_line
      draw_line(@current_line.x, @current_line.y, 0xFFAABBCC,
                mouse_x, mouse_y, 0xFFAABBCC,
                ZOrder::Lines, mode=:default)
    end

  end#}}}

  def button_down(id)#{{{
    case id
    when Gosu::Button::KbEscape
      close
    when Gosu::Button::KbF1
      read_area(@playground.area, "data/playground*.txt")
      i = @playground.area.size + rand(@playground.area.size)
    when Gosu::Button::KbF2
      @grid.toggle
    when Gosu::Button::KbF3
      @grid.inc_step
    when Gosu::Button::KbF4
      @grid.dec_step
    when Gosu::Button::MsLeft
      @click = Coord.new(mouse_x, mouse_y)
      do_tool
    when Gosu::Button::KbSpace
      case @tool
      when :multi_line, :free_line
        @active_lines << @flines
        @flines = []
        @current_line = nil
        tool_change(:none)
      end
    when Gosu::Button::MsRight
      @area_click.empty!
    else
      # some keybord letter
      case button_id_to_char(id)
      when 'a'
        # click area mode
        tool_change(:area)
      when 'f'
        # click free_line mode
        tool_change(:free_line)
      when 'm'
        # click multi free_line mode
        tool_change(:multi_line)
      when 'd'
        if @tool == :area
          if @area_click.size > 0
            # dump the clicked area into a file
            dump_area(@area_click, "data/area")
          else
            puts "no tail to dump"
          end
        else
          puts "current tools is '#{@tool}'"
        end
      when 'l'
        # load area
        begin
          read_area(@area_click, "data/area*.txt")
        rescue RuntimeError
          puts "#{$!} => ok unclosed area"
        end
      when '.' # v on bépo on azerty layout
        # test algorithm of polygon detection
        if @area_click and @area_click.inside?(mouse_x, mouse_y)
          puts "inside"
        else
          puts "outside"
        end
      when '-'
        @monster.factor += 0.1
      when '+'
        @monster.factor -= 0.1
      end
    end
  end#}}}

private
  # load saved area
  def read_area(area_ref, pattern)
    found = false
    first = nil
    Dir.glob(pattern) do |a|
      first ||= a
      next if @area_last_loaded[area_ref] && @area_last_loaded[area_ref].include?(a)

      # pick the next file
      # create the Array and add the file
      (@area_last_loaded[area_ref] ||= []) << a
      found = true
      break
    end

    if ! found
      # reset the list and start again
      @area_last_loaded[area_ref] = [ first ]
    end

    puts "loading: #{@area_last_loaded[area_ref].last}"
    area_ref.read_file(@area_last_loaded[area_ref].last)
  end

  def dump_area(area_ref, pattern)
    n = 0
    fname = nil
    found = false
    max = 30
    while ! found
      fname = pattern + n.to_s + '.txt'
      found = true if ! FileTest.exists?(fname)
      n += 1

      raise "dump_area loop max reach #{max}" if n > max
    end

    puts "dump_area => #{fname}"
    File.open(fname, "w") { |f| area_ref.dump(f) }
  end

  def tool_change(new_tool)
    if not @all_tools.include?(new_tool)
      raise "invalid tool change '#{new_tool}'"
    end

    # do something with current tool
    case @tool
    when :area
    when :free_line, :multi_line
      @flines.clear
      @current_line = nil
    end

    @tool = new_tool

    self
  end

  def do_tool
    p = @grid.snap_point(@click)
    puts "#{@click} #{p} #{@grid}"

    case @tool
    when :area
      # upon mouse click we are making a area
      lastp = @area_click.last
      # check HV line…
      if @area_click.size == 0 or (lastp and (p.x == lastp.x or p.y == lastp.y))
        @area_click << p unless @area_click.points.include?(p)
      end
      puts "#{p}, click=#{@click}"
      puts "#{@click} #{@playground.area.inside?(@click.x, @click.y)}"
    when :free_line
      if @current_line
        # end the current_line with the point
        @flines << FreeLine.new(self, @current_line.dup, p)
        @current_line = nil
      else
        @current_line = p
      end
    when :multi_line
      if @current_line
        # end the current_line with the point
        @flines << FreeLine.new(self, @current_line.dup, p)
        @current_line = p
      else
        @current_line = p
      end
    end
  end

end #}}}

window = GameWindow.new
window.show
