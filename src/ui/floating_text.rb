module GosuGameJam3
  class FloatingText < Entity
    def initialize(text:, colour:, **kw)
      @text = text
      @colour = colour
      @lifetime = 120
      super(**kw)
    end

    attr_accessor :text
    
    attr_accessor :colour

    def tick
      position.y -= 1
      @lifetime -= 1
      self.colour = Gosu::Color.argb(
        [((@lifetime / 60.0) * 255).to_i, 255].min,
        self.colour.red,
        self.colour.green,
        self.colour.blue,
      )

      $mall.misc_entities.delete(self) if @lifetime < 0
    end

    def draw
      return if $state.is_a?(State::SentimentReport)

      $regular_font.draw_text(text, position.x, position.y, 1000, 1, 1, colour)
    end
  end
end
