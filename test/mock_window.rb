$: << '../../gosu-mock/'
require 'gosu_mock'

class MockWindow < Gosu::Window
  def initialize
    super(200,200,false)
  end
  def draw
  end
end
