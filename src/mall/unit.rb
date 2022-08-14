require_relative '../engine/entity'

module GosuGameJam3
  # A store, facility, etc in the mall. Must be used through a derived class.
  class Unit < Entity
    def initialize(floor:, offset:)
      @floor = floor
      @offset = offset

      super(position: $mall.slot_to_point(floor: floor, offset: offset))
    end

    # Which floor of the mall this unit is on. (Zero-indexed, where 0 is ground.)
    attr_accessor :floor

    # The number of slots away from the far-left of the floor this unit is located.
    attr_accessor :offset

    # The number of slots this unit occupies.
    def size
      self.class.size
    end

    # The image of this unit.
    def image
      self.class.image
    end

    # The image of this unit. This is derived from the class' name, by converting it into snake
    # case.
    def self.image
      # This is ActiveRecord's implementation of CamelCase to snake_case
      image_name = self.name
        .split('::')
        .last
        .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
        .gsub(/([a-z\d])([A-Z])/,'\1_\2')
        .tr("-", "_")
        .downcase
  
      Res.image("units/#{image_name}.png")
    end

    # The number of slots this unit occupies, calculated from its image.
    def self.size
      image.width / Mall::SLOT_WIDTH
    end

    def draw
      image.draw(
        position.x,
        position.y,
      )
    end

    # Returns an array of the slot indexes on this floor occupied by this unit.
    def slots_occupied
      (offset...(offset + size)).to_a
    end
  end
end
