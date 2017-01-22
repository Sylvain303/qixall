# vim: set fdm=marker ts=2 sw=2 shellslash commentstring=#%s:
# coding: utf-8
#
# class Playground - handle qix playground behavior
#

require 'area'

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
