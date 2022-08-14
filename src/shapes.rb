module Gosu
  def self.draw_outline_rect(x, y, w, h, c, b)
    Gosu.draw_rect(
      x - b, y - b,
      w + b * 2, b, c
    )
    Gosu.draw_rect(
      x - b, y - b,
      b, h + b * 2, c
    )
    Gosu.draw_rect(
      x - b, y + h,
      w + b * 2, b, c
    )
    Gosu.draw_rect(
      x + w, y - b,
      b, h + b * 2, c
    )
  end
end
