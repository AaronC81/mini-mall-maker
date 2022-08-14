require 'gosu'

require_relative 'engine/point'
require_relative 'mall/mall'
require_relative 'mall/unit'

# Not a pixel art game, but not having this has caused problems with upscaling in the past
Gosu::enable_undocumented_retrofication

$cursor = GosuGameJam3::Point.new(0, 0)

module State
  Idle = Struct.new('Idle')
  PlacingUnit = Struct.new('PlacingUnit', :unit_size, :on_place)
end 

module GosuGameJam3
  WIDTH = 1600
  HEIGHT = 900

  class GameWindow < Gosu::Window
    def initialize
      super(WIDTH, HEIGHT)

      $regular_font = Gosu::Font.new(14, name: "Arial") # TODO - bundle font

      $state = State::Idle

      $mall = Mall.new
      $mall.units << Unit.new(floor: 0, offset: 6, size: 3, _temp_colour: Gosu::Color::RED)
      $mall.units << Unit.new(floor: 0, offset: 10, size: 5, _temp_colour: Gosu::Color::BLUE)
    end

    def update
      $cursor = Point.new(mouse_x.to_i, mouse_y.to_i)
    end

    def draw
      $mall.units.each do |unit|
        unit.draw
      end

      # If placing unit, draw a hologram of the current position
      if $state.is_a? State::PlacingUnit
        floor, offset = $mall.point_to_slot($cursor)
        if !floor.nil? && !offset.nil?
          valid = $mall.can_place?(floor, offset, $state.unit_size)
          point = $mall.slot_to_point(floor: floor, offset: offset)

          Gosu.draw_rect(
            point.x, point.y,
            $state.unit_size * Mall::SLOT_WIDTH, Mall::FLOOR_HEIGHT,
            valid ? Gosu::Color.new(150, 0, 200, 50) : Gosu::Color.new(150, 255, 0, 0)
          )
        end
      end
    end

    def needs_cursor?
      true
    end  

    def button_down(id)
      super # Fullscreen with Alt+Enter/Cmd+F/F11

      # TODO: Temp
      case id
      when Gosu::MS_LEFT
        case $state
        when State::PlacingUnit
          floor, offset = $mall.point_to_slot($cursor)
          if !floor.nil? && !offset.nil? && $mall.can_place?(floor, offset, $state.unit_size)
            $state.on_place.(floor, offset)
          end
        end
      when Gosu::KB_U
        $state = State::PlacingUnit.new(
          3,
          ->(floor, offset) {
            p [floor, offset]
            $state = State::Idle
          }
        )
      end 
    end
  end
end

GosuGameJam3::GameWindow.new.show
