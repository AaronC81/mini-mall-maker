require 'gosu'

require_relative 'engine/point'

# Not a pixel art game, but not having this has caused problems with upscaling in the past
Gosu::enable_undocumented_retrofication

$cursor = GosuGameJam3::Point.new(0, 0)

module GosuGameJam3
  WIDTH = 1600
  HEIGHT = 900

  class GameWindow < Gosu::Window
    def initialize
      super(WIDTH, HEIGHT)
    end

    def update
      $cursor = Point.new(mouse_x.to_i, mouse_y.to_i)
    end

    def draw
      Gosu.draw_rect(50, 50, 10, 10, Gosu::Color::RED)
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
