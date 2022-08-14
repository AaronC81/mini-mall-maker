module GosuGameJam3
  # A mixin which enables an object to show a tooltip when hovered.
  #
  # The object must have the following methods:
  #   #position -> Point
  #   #width -> Integer
  #   #height -> Integer
  module Tooltip
    # An optional tooltip to display when the button is hovered. The tooltip may have multiple
    # lines.
    attr_accessor :tooltip

    # Whether the object is drawn centered on `#position`, or from the top left. true if centered.
    def drawn_centred?
      false
    end

    # Checks if a point is inside this object.
    def point_inside?(point)
      if drawn_centred?
        point.x >= position.x - width / 2 && point.x <= position.x + width / 2 \
          && point.y >= position.y - height / 2 && point.y <= position.y + height / 2
      else
        point.x >= position.x && point.x <= position.x + width \
          && point.y >= position.y && point.y <= position.y + height
      end
    end

    # Draws the tooltip if the object is being hovered. If a block is passed, the block is executed
    # after the tooltip is drawn.
    def draw_tooltip(&block)
      if tooltip && point_inside?($cursor)
        # Find how tall the tooltip needs to be
        lines = tooltip.split("\n")
        text_width = lines.map { |l| $regular_font.text_width(l) }.max
        text_height = lines.length * $regular_font.height

        # Draw rectangle with some padding, clamp to edges of screen
        padding = 10
        origin_x = [$cursor.x, WIDTH - (text_width + padding * 2)].min
        origin_y = [$cursor.y, text_height + padding * 2].max
        Gosu.draw_rect(
          origin_x, origin_y - text_height - padding * 2,
          text_width + padding * 2, text_height + padding * 2,
          Gosu::Color.argb(0xDD, 0x00, 0x00, 0x00), 1000,
        )
        $regular_font.draw_text(
          tooltip, origin_x + padding, origin_y - text_height - padding, 1000, 1, 1,
          Gosu::Color::WHITE,
        )

        block&.()
      end
    end
  end
end
