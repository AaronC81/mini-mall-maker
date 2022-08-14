require 'gosu'

require_relative 'res'
require_relative 'shapes'
require_relative 'engine/point'
require_relative 'mall/mall'
require_relative 'mall/unit'
require_relative 'mall/units'
require_relative 'ui/toolbar'

# Not a pixel art game, but not having this has caused problems with upscaling in the past
Gosu::enable_undocumented_retrofication

$cursor = GosuGameJam3::Point.new(0, 0)

module GosuGameJam3
  module State
    Idle = Struct.new('Idle')
    PlacingUnit = Struct.new('PlacingUnit', :unit_class)
  end 
  
  WIDTH = 1600
  HEIGHT = 900

  class GameWindow < Gosu::Window
    def initialize
      super(WIDTH, HEIGHT)

      # TODO: bundle fonts
      $regular_font = Gosu::Font.new(30, name: "Arial")

      $state = State::Idle

      $mall = Mall.new
      $mall.units << Units::HighEndTechnology.new(floor: 0, offset: 6)

      @toolbar = Toolbar.new
    end

    def update
      $cursor = Point.new(mouse_x.to_i, mouse_y.to_i)
      @toolbar.tick

      $click = false
    end

    def draw
      $mall.units.each do |unit|
        unit.draw
      end

      # If placing unit, draw a hologram of the current position
      if $state.is_a? State::PlacingUnit
        floor, offset = $mall.point_to_slot($cursor)
        if !floor.nil? && !offset.nil?
          valid = $mall.can_place?(floor, offset, $state.unit_class.size)
          point = $mall.slot_to_point(floor: floor, offset: offset)

          Gosu.draw_rect(
            point.x, point.y,
            $state.unit_class.size * Mall::SLOT_WIDTH, Mall::FLOOR_HEIGHT,
            valid ? Gosu::Color.new(150, 0, 200, 50) : Gosu::Color.new(150, 255, 0, 0)
          )
        end
      end

      @toolbar.draw
    end

    def needs_cursor?
      true
    end  

    def button_down(id)
      super # Fullscreen with Alt+Enter/Cmd+F/F11

      # TODO: Temp
      case id
      when Gosu::MS_LEFT
        $click = true

        case $state
        when State::PlacingUnit
          floor, offset = $mall.point_to_slot($cursor)
          if !floor.nil? && !offset.nil? && $mall.can_place?(floor, offset, $state.unit_class.size)
            $mall.units << $state.unit_class.new(floor: floor, offset: offset)
            $state = State::Idle
          end
        end
      end 
    end
  end
end

GosuGameJam3::GameWindow.new.show
