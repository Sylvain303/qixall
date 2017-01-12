#vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
require 'rubygems'
require 'bundler/setup'
$:.push('.')
require 'gosu'
require 'coord'
require 'player'
require 'polygon'
require 'area'
require 'star'

require 'pry'
require 'pry-nav'

#require 'debugger'
#Debugger.start(:post_mortem => true)

module ZOrder
  Background, Grid, Lines, Stars, Monster, Player, UI, Mouse = *0..20
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

		# a surrounding box
		@b = Box.new(@window, @me - mid, @me + mid)
	end
	
	attr_reader :me

	def start(area)
		@area = area
		@start = @area[0]
		@x, @y = @start.x + @image.width, @start.y + @image.height
		@speed = 4
		# @angle = rand(360)
	end

	def draw
		@image.draw_rot(@me.x, @me.y, ZOrder::Monster, @angle, 0.5, 0.5, @factor, @factor)
		@window.draw_point(@me)
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

class Tropedo#{{{
	def initialize(window, dir)
		@window = window
		@dir = dir
		@image = Gosu::Image.new(@window, "media/torpedo.png", false)
		@angle = 90.0
	end

	def move
		@x += @dir.x
		@y += @dir.y
	end

	def draw
		@image.draw_rot(@dir.x, @dir.x, ZOrder::Monster, @angle)
	end

end#}}}

class Playground#{{{
	def initialize(window)
		@window = window
		@background_image = Gosu::Image.new(@window, "media/pokemon_2.png", true)
		#@background_image = Gosu::Image.new(@window, "media/epoc-01.png", true)
		#@background_image = Gosu::Image.new(@window, "media/monica.png", true)

		# initialize with default playground
		@area = Area.new(@window)
		@area.read_file("data/playground0.txt")
		@tcorner, @bcorner = @area.corners
		@area.color = 0xFF4dd0bc
	end
	attr_reader :area, :tcorner, :bcorner

	def color=(c)
		@area.color = c
	end

	def draw
		@background_image.draw(@tcorner.x, @tcorner.y, ZOrder::Background);
		## a test to highlight the nearest edge of the mouse pointer
		#edge = @area.find_nearest_edge(@window.mouse_x, @window.mouse_y)
		#@area.highlight = edge
		@area.draw
	end
end#}}}

class GameWindow < Gosu::Window#{{{
	def initialize#{{{
		@screen_w = 640
		@screen_h = 480
		super(@screen_w, @screen_h, false, 10)
		self.caption = "Qixall"

		@epais = LINEW
		@grid = GRID

		@playground = Playground.new(self)

		@monster = Monster.new(self)
		@monster.start(@playground.area)

		@player = Player.new(self)
		@player.start(@playground.area, 0, 3)

		@font = Gosu::Font.new(self, Gosu::default_font_name, 20)
		@cursor = Gosu::Image.new(self, "media/Cursor.png", false)

		@area_click = Area.new(self)
		@area_last_loaded = {}
		@show_grid = true

		# stars from tutorial…
		@star_anim = Gosu::Image::load_tiles(self, "media/Star.png", 25, 25, false)
		@stars = Array.new
	end#}}}
	attr_reader :epais, :grid, :screen_h, :screen_w, :playground, :monster
	attr_accessor :tail

	def update#{{{
		

		if button_down? Gosu::Button::KbLeft
			@player.change_dir(:left)
		end
		if button_down? Gosu::Button::KbRight
			@player.change_dir(:right)
		end
		if button_down? Gosu::Button::KbUp
			@player.change_dir(:up)
		end
		if button_down? Gosu::Button::KbDown
			@player.change_dir(:down)
		end

		if button_down? Gosu::Button::KbSpace
			@player.stop
		end

		@player.move
		@monster.move

		# and some random stars to animated the game and test framed sprite code
		if rand(100) < 4 and @stars.size < 25 then
			@stars.push(Star.new(@star_anim))
		elsif rand(100) < 10 and @stars.size > 10
			@stars.shift()
		end
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
		@monster.draw
		@player.draw
		@playground.draw
		@cursor.draw(mouse_x, mouse_y, ZOrder::Mouse)
		@stars.each { |star| star.draw }

		# info
		@font.draw("mouse pos: #{mouse_x}, #{mouse_y}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
		@font.draw("grid: #{@grid}", 470, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)
		@font.draw("clic: #{@click}", 10, 10 + 1*15, ZOrder::UI, 1.0, 1.0, 0xffffff00)
		player_info = "player: #{@player.current_dir}, #{@player.next_dir}, #{@player.zone}"
		@font.draw(player_info, 330, 10 + 1*15, ZOrder::UI, 1.0, 1.0, 0xffffff00)
		@font.draw("area: #{@playground.area.size}", 230, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00)

		@area_click.draw if @area_click

		if @show_grid
			# http://www.ruby-doc.org/core-1.9.3/Numeric.html#method-i-step
			# Vertical
			@playground.tcorner.x.step(@playground.bcorner.x, @grid) { |i| 
				draw_line(i, @playground.tcorner.y, 0xFFbbbbbb, i, @playground.bcorner.y, 0xFFbbbbbb, ZOrder::Grid, mode=:default)
			}
			# Horizontal
			@playground.tcorner.y.step(@playground.bcorner.y, @grid) { |i| 
				draw_line(@playground.tcorner.x, i, 0xFFbbbbbb, @playground.bcorner.x, i, 0xFFbbbbbb, ZOrder::Grid, mode=:default)
			}
		end
	end#}}}

	def button_down(id)#{{{
		case id
		when Gosu::Button::KbEscape
			close
		when Gosu::Button::KbF1
			read_area(@playground.area, "data/playground*.txt")
			i = @playground.area.size + rand(@playground.area.size)
			@player.start(@playground.area, i % @playground.area.size, (i + 1) % @playground.area.size)
		when Gosu::Button::KbF2
			@show_grid = ! @show_grid
		when Gosu::Button::KbF3
			@grid += 1
		when Gosu::Button::KbF4
			@grid -= 1
		when Gosu::Button::MsLeft
			# upon mouse click we are making a area
			@click = Coord.new(mouse_x, mouse_y)
			p = @click.snap(@grid)
			lastp = @area_click.last
			# check HV line…
			if @area_click.size == 0 or (lastp and (p.x == lastp.x or p.y == lastp.y))
				@area_click << p unless @area_click.points.include?(p)
			end
			puts "#{p}, click=#{@click}"
			puts "#{@click} #{@playground.area.inside?(@click.x, @click.y)}"
		when Gosu::Button::MsRight
			@area_click.empty!
		when Gosu::Button::KbLeftControl, Gosu::Button::KbRightControl
			@player.action(:down)
		else
			# some keybord letter
			case button_id_to_char(id)
			when 'd'
				if @area_click.size > 0
					# dump the clicked area into a file
					dump_area(@area_click, "data/area")
				else
					puts "no tail to dump"
				end
			when 'l'
				# load area
				begin 
					read_area(@area_click, "data/area*.txt")
				rescue RuntimeError
					puts "#{$!} => ok unclosed area"
				end
			when '.' # v on bépo
				# test algorithm of polygon detection
				if @area_click and @area_click.inside?(mouse_x, mouse_y)
					puts "inside"
				else
					puts "outside"
				end
			end
		end
	end#}}}

	def button_up(id)
		case id
		when Gosu::Button::KbLeftControl, Gosu::Button::KbRightControl
			@player.action(:up)
		end
	end

private
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

		puts "dump_area	=> #{fname}"
		File.open(fname, "w") { |f| area_ref.dump(f) }
	end
end #}}}

window = GameWindow.new
window.show


