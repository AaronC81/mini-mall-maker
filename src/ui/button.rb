require_relative '../engine/entity'
require_relative 'tooltip'
require_relative '../utils'

module GosuGameJam3
  class Button < Entity
    include Tooltip

    def initialize(width: nil, height: nil, text: nil, image: nil, on_click: nil, enabled: nil, tooltip: nil, cost: nil, highlighted: false, **kw)
      super(**kw)
      @width = width
      @height = height
      @text = text
      @image = image
      if image
        @width = image.width
        @height = image.height
      end
      @on_click = on_click
      @enabled = enabled || ->{ true }
      @tooltip = tooltip
      @cost = cost
      @highlighted = highlighted
    end

    attr_accessor :width
    attr_accessor :height

    # The text to display on this button.
    attr_accessor :text

    # A proc to run when the button is clicked.
    attr_accessor :on_click

    # A proc to run to check the button is enabled.
    attr_accessor :enabled

    # An image to display instead of the standard button text.
    attr_accessor :image

    # The price of the item this button is associated with. If the player's money is below this,
    # the button will not be clickable. (Clicking the button does not reduce money.)
    attr_accessor :cost

    # Whether this button is constantly its hover colour.
    attr_accessor :highlighted

    def background_colour
      return Gosu::Color::BLACK unless enabled.()

      if point_inside?($cursor) || highlighted
        Gosu::Color.rgb(70, 65, 50)
      else
        Gosu::Color.rgb(132, 116, 95)
      end
    end

    def draw
      if image
        image.draw(position.x, position.y, 100, 1, 1, enabled.() ? Gosu::Color::WHITE : Gosu::Color.rgb(70, 70, 70))
      else
        # Draw fill
        Gosu.draw_rect(position.x, position.y, width, height, background_colour)

        # Draw border
        border_width = 2
        border_colour = Gosu::Color::BLACK
        Gosu.draw_outline_rect(position.x, position.y, width, height, Gosu::Color::BLACK, 2)

        # Draw text
        text_width = $regular_font.text_width(text)
        text_height = $regular_font.height * (text.chars.select { |x| x == "\n" }.count + 1)
        if cost
          text_height += $regular_font.height
          $regular_font.draw_text(
            text,
            position.x + (width - text_width) / 2,
            position.y + (height - text_height) / 2,
            2
          )
          formatted_cost = Utils.format_money(cost)
          $regular_font.draw_text(
            formatted_cost,
            position.x + (width - $regular_font.text_width(formatted_cost)) / 2,
            position.y + (height - text_height) / 2 + $regular_font.height,
            2,
            1,
            1,
            $mall.money >= cost ? Gosu::Color::WHITE : Gosu::Color::RED,
          )
        else
          $regular_font.draw_text(
            text,
            position.x + (width - text_width) / 2,
            position.y + (height - text_height) / 2,
            2
          )
        end
      end

      draw_tooltip
    end

    def tick
      if $click && point_inside?($cursor) && enabled.() && (cost ? $mall.money >= cost : true)
        on_click&.()
        $click = false
      end
    end
  end
end
