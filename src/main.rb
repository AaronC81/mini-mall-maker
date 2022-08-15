require 'gosu'

require_relative 'res'
require_relative 'shapes'
require_relative 'engine/point'
require_relative 'mall/mall'
require_relative 'mall/unit'
require_relative 'mall/units'
require_relative 'ui/toolbar'
require_relative 'customer'

$cursor = GosuGameJam3::Point.new(0, 0)

module GosuGameJam3
  module State
    Idle = Struct.new('Idle')
    PlacingUnit = Struct.new('PlacingUnit', :unit_class)
    DemolishUnit = Struct.new('DemolishUnit')
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

      @toolbar = Toolbar.new
    end

    def update
      $cursor = Point.new(mouse_x.to_i, mouse_y.to_i)
      @toolbar.tick
      $mall.tick

      $click = false
    end

    def draw
      Gosu.draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.new(255, 170, 202, 242))

      $mall.draw 

      case $state
      when State::PlacingUnit
        # If placing unit, draw a hologram of the current position
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

      when State::DemolishUnit
        # If demolishing a unit, highlight it
        floor, offset = $mall.point_to_slot($cursor)
        if !floor.nil? && !offset.nil? && (unit = $mall.unit_at(floor, offset))
          point = $mall.slot_to_point(floor: unit.floor, offset: unit.offset)

          Gosu.draw_rect(
            point.x, point.y,
            unit.size * Mall::SLOT_WIDTH, Mall::FLOOR_HEIGHT,
            Gosu::Color.new(150, 0, 50, 200),
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

        when State::DemolishUnit
          floor, offset = $mall.point_to_slot($cursor)
          if !floor.nil? && !offset.nil? && (unit = $mall.unit_at(floor, offset))
            $mall.units.delete(unit)
            $state = State::Idle
          end
        end

      # TODO: temp
      when Gosu::KB_C
        $mall.customers << Customer.new(
          intent: Customer::Intent::Browse.new,
          preferences: Customer::Preferences::new.tap do |p|
            p.interests = [Customer::Preferences::Department::Fashion]
            p.budget = [Customer::Preferences::Budget::Discount, Customer::Preferences::Budget::HighEnd].sample
          end,
          position: Point.new(100, Mall::BOTTOM_FLOOR_Y + Mall::FLOOR_HEIGHT - 30)
        )
      end 
    end
  end
end

GosuGameJam3::GameWindow.new.show
