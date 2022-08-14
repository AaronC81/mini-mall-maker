require_relative '../engine/entity'

module GosuGameJam3
  # A store, facility, etc in the mall.
  class Unit < Entity
    def initialize(floor:, offset:, size:, _temp_colour:)
      @floor = floor
      @offset = offset
      @size = size
      @_temp_colour = _temp_colour

      super(position: $mall.slot_to_point(floor: floor, offset: offset))
    end

    # Which floor of the mall this unit is on. (Zero-indexed, where 0 is ground.)
    attr_accessor :floor

    # The number of slots away from the far-left of the floor this unit is located.
    attr_accessor :offset

    # The number of slots this unit occupies.
    attr_accessor :size

    def draw
      Gosu.draw_rect(position.x, position.y, size * Mall::SLOT_WIDTH, Mall::FLOOR_HEIGHT, @_temp_colour)
    end

    # Returns an array of the slot indexes on this floor occupied by this unit.
    def slots_occupied
      (offset...(offset + size)).to_a
    end
  end
end
