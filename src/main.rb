require 'gosu'

require_relative 'engine/point'
require_relative 'mall/mall'
require_relative 'mall/unit'

# Not a pixel art game, but not having this has caused problems with upscaling in the past
Gosu::enable_undocumented_retrofication

$cursor = GosuGameJam3::Point.new(0, 0)

module GosuGameJam3
  WIDTH = 1600
  HEIGHT = 900

  class GameWindow < Gosu::Window
    def initialize
      super(WIDTH, HEIGHT)

      $mall = Mall.new
      $mall.units << Unit.new(floor: 0, offset: 0, size: 3, _temp_colour: Gosu::Color::RED)
      $mall.units << Unit.new(floor: 0, offset: 4, size: 5, _temp_colour: Gosu::Color::BLUE)
    end

    def update
      $cursor = Point.new(mouse_x.to_i, mouse_y.to_i)
    end

    def draw
      $mall.units.each do |unit|
        unit.draw
      end
    end

    def needs_cursor?
      true
    end  

    def button_down(id)
      super # Fullscreen with Alt+Enter/Cmd+F/F11

    end
  end
end

GosuGameJam3::GameWindow.new.show
