module GosuGameJam3
  class Point
    attr_accessor :x, :y, :z

    def initialize(x, y, z = 0)
      @x = x
      @y = y
      @z = z
    end

    def +(other)
      raise "can't add point to #{other}" unless other.is_a?(Point)
      Point.new(x + other.x, y + other.y, z + other.z)
    end 

    def distance(other)
      x_dist = (x - other.x)
      y_dist = (y - other.y)
      Math.sqrt(x_dist**2 + y_dist**2)
    end
  end
end
