# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# class Grid for editor - tool
#

require 'coord'

class Grid
  def initialize(window, grid_step)
    @window = window
    @grid_step = grid_step
    @show_grid = true
  end

  def inc_step(inc=1)
    @grid_step += inc
  end
  def dec_step(inc=1)
    @grid_step -= inc
  end

  def to_s
    "#@grid_step"
  end

  def snap_point(coord)
    # offset 
    p = (coord - @window.playground.tcorner).snap(@grid_step)
    p + @window.playground.tcorner
  end

  def draw
    if @show_grid
      # http://www.ruby-doc.org/core-1.9.3/Numeric.html#method-i-step
      # Vertical
      @window.playground.tcorner.x.step(
        @window.playground.bcorner.x, @grid_step) do |i|
          @window.draw_line(i, @window.playground.tcorner.y, 0xFFbbbbbb,
                    i, @window.playground.bcorner.y, 0xFFbbbbbb,
                    ZOrder::Grid, mode=:default)
        end
      # Horizontal
      @window.playground.tcorner.y.step(
        @window.playground.bcorner.y, @grid_step) do |i|
          @window.draw_line(@window.playground.tcorner.x, i, 0xFFbbbbbb,
                    @window.playground.bcorner.x, i, 0xFFbbbbbb,
                    ZOrder::Grid, mode=:default)
        end
    end
  end

  def toggle
    @show_grid = ! @show_grid
  end
end

