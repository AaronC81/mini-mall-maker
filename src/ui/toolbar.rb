require_relative 'button'
require_relative '../engine/point'
require_relative '../mall/units'
require_relative '../utils'

module GosuGameJam3
  class Toolbar
    TOOLBAR_HEIGHT = 150

    AdvertisingMethod = Struct.new('AdvertisingMethod', :description, :interests, :cost)
    AM = AdvertisingMethod

    D = Customer::Preferences::Department

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
                    ["Fast Fashion", nil, Units::DiscountClothes],
                    ["Designer Brand", nil, Units::DesignerClothes],
                    ["Shoes", nil, Units::Shoes],
                  ])
                end
              ],
              [
                "Technology...", nil, ->do
                  open_buttons([
                    ["High-end Tech", nil, Units::HighEndTechnology],
                    ["Used Tech", nil, Units::UsedTechnology],
                    ["Phone Cases", nil, Units::PhoneCases],
                  ])
                end
              ],
              [
                "Toys and\nGames...", nil, ->do
                  open_buttons([
                    ["General Toys", nil, Units::GeneralToys],
                    ["Plushies", nil, Units::PlushToys],
                    ["Building Bricks", nil, Units::BuildingBlockToys],
                    ["Video Games", nil, Units::VideoGames],
                  ])
                end
              ],
              [
                "Health and\nBeauty...", nil, ->do
                  open_buttons([
                    ["Pharmacy", nil, Units::Pharmacy],
                    ["Cosmetics", nil, Units::Cosmetics],
                    ["Luxury Soap", nil, Units::LuxurySoap],
                  ])
                end
              ],
              [
                "Food...", nil, ->do
                  open_buttons([
                    ["Bakery", nil, Units::Bakery],
                    ["Donuts", nil, Units::Donuts],
                    ["Burritos", nil, Units::Burritos],
                    ["Fine Dining", nil, Units::FineDining],
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
        ["Advertising...", "Increase your mall's popularity, and target specific interests.", ->do
          open_buttons([
            ["Newspaper", nil, AM.new("General-purpose marketing.", [], 400)],
            ["Influencers", nil, AM.new("Attract trendy, fashion-focused customers.", [D::Fashion, D::Health], 600)],
            ["In-Game Ad", nil, AM.new("Advertise to gadget and gaming lovers.", [D::Technology, D::Toys], 600)],
            ["Meal Coupons", nil, AM.new("Get people to come and eat at your mall.", [D::Food], 400)],
          ])
        end],
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
          elsif click.is_a?(AdvertisingMethod)
            cost = click.cost
            tooltip = click.description
            interests = click.interests
            click = ->do
              $mall.money -= cost
              $mall.popularity *= 1.25
              interests.each do |interest|
                $mall.interest_reputation[interest] += 5
              end
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
