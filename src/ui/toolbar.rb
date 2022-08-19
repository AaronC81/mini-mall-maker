require_relative 'button'
require_relative '../engine/point'
require_relative '../mall/units'
require_relative '../utils'

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

      if cancellable_state?
        @cancel_button.draw
      else
        @buttons.each do |button|
          button.draw
        end
      end

      # Print money (heh)
      money_reading = Utils.format_money($mall.money)
      money_width = $regular_font.text_width(money_reading)
      $regular_font.draw_text(
        money_reading,
        WIDTH - money_width - 20,
        HEIGHT - TOOLBAR_HEIGHT + 25,
        10,
        1,
        1,
        Gosu::Color::BLACK,
      )
    end

    def tick
      if cancellable_state?
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
                    ["Discount", Units::DiscountClothes],
                    ["Designer", Units::DesignerClothes],
                  ])
                end
              ],
              [
                "Technology...", ->do
                  open_buttons([
                    ["High-end", Units::HighEndTechnology],
                  ])
                end
              ],
            ])
          end
        ],
        ["Build Floor", -> { $mall.floors += 1 }],
        ["Demolish", -> { $state = State::DemolishUnit.new }],
      ])
    end

    def open_buttons(buttons)
      @buttons = []
      buttons.each.with_index do |(text, click), i|
        # `click` special cases
        unless click.is_a?(Proc)
          if click < Unit
            unit = click
            cost = unit.build_cost
            click = -> { place(unit) }
          end
        end

        @buttons << Button.new(
          width: 200,
          height: 60,
          text: text,
          position: Point.new(10 + 210 * (i / 2), HEIGHT - TOOLBAR_HEIGHT + (i.even? ? 10 : 80)),
          on_click: click,
          cost: cost,
        )
      end
    end

    def place(unit_class)
      $state = State::PlacingUnit.new(unit_class)
      open_main_menu
    end

    def cancellable_state?
      $state.is_a?(State::PlacingUnit) || $state.is_a?(State::DemolishUnit)
    end
  end
end
