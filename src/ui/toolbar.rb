require_relative 'button'
require_relative '../engine/point'
require_relative '../mall/units'

module GosuGameJam3
  class Toolbar
    TOOLBAR_HEIGHT = 150

    def initialize
      @cancel_button = Button.new(
        width: 200,
        height: 60,
        text: "Cancel",
        position: Point.new(10, HEIGHT - TOOLBAR_HEIGHT + 10),
        on_click: -> { $state = State::Idle },
      )
      open_main_menu
    end

    def draw
      # Draw background
      Gosu.draw_rect(0, HEIGHT - TOOLBAR_HEIGHT, WIDTH, TOOLBAR_HEIGHT, Gosu::Color::GRAY)

      if $state.is_a? State::PlacingUnit
        @cancel_button.draw
      else
        @buttons.each do |button|
          button.draw
        end
      end
    end

    def tick
      if $state.is_a? State::PlacingUnit
        @cancel_button.tick
      else
        @buttons.each do |button|
          button.tick
        end
      end
    end

    def open_main_menu
      open_buttons([
        [
          "Build Stores", ->do
            open_buttons([
              [
                "Fashion...", ->do
                  open_buttons([
                    ["Discount", -> { place(Units::DiscountClothes) }],
                    ["Designer", -> { place(Units::DesignerClothes) }],
                  ])
                end
              ],
              [
                "Technology...", ->do
                  open_buttons([
                    ["High-end", -> { place(Units::HighEndTechnology) }],
                  ])
                end
              ],
            ])
          end
        ],
      ])
    end

    def open_buttons(buttons)
      @buttons = []
      buttons.each.with_index do |(text, click), i|
        @buttons << Button.new(
          width: 200,
          height: 60,
          text: text,
          position: Point.new(10 + 210 * (i / 2), HEIGHT - TOOLBAR_HEIGHT + (i.even? ? 10 : 80)),
          on_click: click,
        )
      end
    end

    def place(unit_class)
      $state = State::PlacingUnit.new(unit_class)
      open_main_menu
    end
  end
end
