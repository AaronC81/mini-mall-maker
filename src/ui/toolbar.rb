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
        position: Point.new(70, HEIGHT - TOOLBAR_HEIGHT + 10),
        on_click: -> { $state = State::Idle.new },
      )
      @sentiment_button = Button.new(
        width: 50,
        height: 60,
        text: "Snt.",
        position: Point.new(WIDTH - 140, HEIGHT - TOOLBAR_HEIGHT + 80),
        on_click: ->do
          unless $state.is_a?(State::SentimentReport)
            $state = State::SentimentReport.new
          else
            $state = State::Idle.new
          end
        end,
      )
      @customers_button = Button.new(
        width: 50,
        height: 60,
        text: "Cst.",
        position: Point.new(WIDTH - 70, HEIGHT - TOOLBAR_HEIGHT + 80),
        on_click: ->do
          unless $state.is_a?(State::CustomerReport)
            $state = State::CustomerReport.new
          else
            $state = State::Idle.new
          end
        end,
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

      @sentiment_button.draw
      @customers_button.draw

      # Print money (heh)
      money_reading = Utils.format_money($mall.money)
      money_width = $regular_font.text_width(money_reading)
      $regular_font.draw_text(
        money_reading,
        WIDTH - money_width - 10,
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

      @sentiment_button.tick
      @sentiment_button.highlighted = $state.is_a?(State::SentimentReport)
      @customers_button.tick
      @customers_button.highlighted = $state.is_a?(State::CustomerReport)
    end

    def open_main_menu
      open_buttons([
        [
          "Build Stores...", "Build a variety of stores for your customers to visit.", ->do
            open_buttons([
              [
                "Fashion...", nil, ->do
                  open_buttons([
                    ["Discount", nil, Units::DiscountClothes],
                    ["Designer", nil, Units::DesignerClothes],
                  ])
                end
              ],
              [
                "Technology...", nil, ->do
                  open_buttons([
                    ["High-end", nil, Units::HighEndTechnology],
                  ])
                end
              ],
            ])
          end
        ],
        [
          "Build Utilities...", "Build extra facilities which your mall needs.", ->do
            open_buttons([
              ["Elevator", "Elevators let customers move between floors.\nThey must be placed in the same position on each floor.", Units::Elevator],
            ])
          end
        ],
        ["Build Floor", "Build a new floor. You will also need to build elevators\n(in Utilities) to allow customers to get there.", :build_floor],
        ["Demolish", "Destroy something you have built.", -> { $state = State::DemolishUnit.new }],
      ], top_level: true)
    end

    def open_buttons(buttons, top_level: false)
      @buttons = []
      buttons.each.with_index do |(text, tooltip, click), i|
        highlighted = false
        # `click` special cases
        unless click.is_a?(Proc)
          if click.is_a?(Class) && click < Unit
            unit = click
            cost = unit.build_cost
            click = -> { place(unit) }
          elsif click == :build_floor
            if $mall.floors < Mall::MAX_FLOORS
              cost = Mall::FLOOR_UPGRADE_COSTS[$mall.floors]
              click = ->do
                $mall.money -= Mall::FLOOR_UPGRADE_COSTS[$mall.floors]
                $mall.floors += 1
                open_main_menu
              end
            else
              text = "Max Floors"
              highlighted = true
              click = ->{}
            end
          end
        end

        @buttons << Button.new(
          width: 200,
          height: 60,
          text: text,
          position: Point.new(70 + 210 * (i / 2), HEIGHT - TOOLBAR_HEIGHT + (i.even? ? 10 : 80)),
          on_click: click,
          cost: cost,
          highlighted: highlighted,
          tooltip: tooltip,
        )
      end

      unless top_level
        @buttons << Button.new(
          width: 50,
          height: TOOLBAR_HEIGHT - 20,
          text: "<",
          position: Point.new(10, HEIGHT - TOOLBAR_HEIGHT + 10),
          on_click: -> { open_main_menu },
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
