require_relative '../engine/entity'
require_relative 'tooltip'

module GosuGameJam3
  class Button < Entity
    include Tooltip

    def initialize(width: nil, height: nil, text: nil, image: nil, on_click: nil, enabled: nil, tooltip: nil, **kw)
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

    def background_colour
      return Gosu::Color::BLACK unless enabled.()

      if point_inside?($cursor)
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
        $regular_font.draw_text(
          text,
          position.x + (width - text_width) / 2,
          position.y + (height - text_height) / 2,
          2
        )
      end

      draw_tooltip
    end

    def tick
      if $click && point_inside?($cursor) && enabled.()
        on_click&.()
        $click = false
      end
    end
  end
end
