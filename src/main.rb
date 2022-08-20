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
    SentimentReport = Struct.new('SentimentReport')
    CustomerReport = Struct.new('CustomerReport')
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

      when State::SentimentReport
        # Draw background
        width_padding, height_padding = draw_report_bg

        # Write most widely-held sentiments
        sentiment_counts = {}
        $mall.sentiments.each do |s|
          sentiment_counts[s.message] ||= [0, s.kind]
          sentiment_counts[s.message][0] += 1
        end
        sentiment_counts = sentiment_counts.sort_by { |_, (v, _)| v }.reverse.to_h
        spacing = $regular_font.height * 1.2

        sentiment_counts.take(20).each.with_index do |(text, (count, kind)), i|
          $regular_font.draw_text(
            count.to_s,
            width_padding + 10, height_padding + 10 + i * spacing, 100,
            1, 1, Gosu::Color::BLACK,
          )
          $regular_font.draw_text(
            text,
            width_padding + 80, height_padding + 10 + i * spacing, 100,
            1, 1, kind == :positive ? Gosu::Color.rgb(0, 170, 50) : Gosu::Color::rgb(225, 20, 0),
          )
        end

      when State::CustomerReport
        # Draw background
        width_padding, height_padding = draw_report_bg

        # Write most widely-held interests
        interest_counts = $mall.customers
          .flat_map { |c| c.preferences.interests }
          .map { |i| i.name.capitalize }
          .tally
          .sort_by { |_, v| v }
          .reverse
          .to_h
        spacing = $regular_font.height * 1.2

        $regular_font.draw_text(
          "#{$mall.customers.length} customers here now",
          width_padding + 10, height_padding + 10, 100,
          1, 1, Gosu::Color::BLACK,
        )
        $regular_font.draw_text(
          "Interests:",
          width_padding + 10, height_padding + 65, 100,
          1, 1, Gosu::Color::BLACK,
        )

        interest_counts.take(12).each.with_index do |(text, count), i|
          $regular_font.draw_text(
            count.to_s,
            width_padding + 10, height_padding + 100 + i * spacing, 100,
            1, 1, Gosu::Color::BLACK,
          )
          $regular_font.draw_text(
            text,
            width_padding + 80, height_padding + 100 + i * spacing, 100,
            1, 1, Gosu::Color::BLACK,
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
          if !floor.nil? && !offset.nil? && $mall.can_place?(floor, offset, $state.unit_class.size) && $mall.money >= $state.unit_class.build_cost
            $mall.units << $state.unit_class.new(floor: floor, offset: offset)
            $mall.money -= $state.unit_class.build_cost
            $state = State::Idle.new
          end

        when State::DemolishUnit
          floor, offset = $mall.point_to_slot($cursor)
          if !floor.nil? && !offset.nil? && (unit = $mall.unit_at(floor, offset))
            $mall.units.delete(unit)
            $state = State::Idle.new
          end
        end
      end
    end

    def draw_report_bg
      width_padding = 200
      height_padding = 30
      Gosu.draw_rect(
        width_padding, height_padding,
        WIDTH - width_padding * 2, HEIGHT - Toolbar::TOOLBAR_HEIGHT - height_padding * 2,
        Gosu::Color.new(255, 240, 240, 240),
      )
      Gosu.draw_outline_rect(
        width_padding, height_padding,
        WIDTH - width_padding * 2, HEIGHT - Toolbar::TOOLBAR_HEIGHT - height_padding * 2,
        Gosu::Color::BLACK, 3
      )

      [width_padding, height_padding]
    end
  end
end

GosuGameJam3::GameWindow.new.show
