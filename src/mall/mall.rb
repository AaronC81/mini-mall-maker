module GosuGameJam3
  # The overall game state.
  # There is one instance of this class, accessible with `$mall`.
  class Mall
    SLOT_WIDTH = 50
    SLOTS_PER_FLOOR = 30
    FLOOR_HEIGHT = 200
    BOTTOM_FLOOR_Y = 600

    def initialize
      @floors = 1
      @units = []
    end

    # The number of floors the mall has.
    attr_accessor :floors

    # All of the units in the mall.
    attr_accessor :units

    # Maps a floor and offset into an engine point where the unit should be located.
    def slot_to_point(floor:, offset:)
      padding = (WIDTH - (SLOT_WIDTH * SLOTS_PER_FLOOR)) / 2
      
      Point.new(padding + SLOT_WIDTH * offset, BOTTOM_FLOOR_Y - FLOOR_HEIGHT * floor)
    end

    # Maps a point to a floor and offset. Returns [floor, offset], or nil if the cursor is not on a
    # slot.
    def point_to_slot(point)
      padding = (WIDTH - (SLOT_WIDTH * SLOTS_PER_FLOOR)) / 2

      floor = (BOTTOM_FLOOR_Y - point.y) / FLOOR_HEIGHT + 1
      return nil if floor < 0 || floor >= floors

      offset = (point.x - padding) / SLOT_WIDTH
      return nil if offset < 0 || offset >= SLOTS_PER_FLOOR

      [floor, offset]
    end

    # Returns true if it is possible to place a unit with the given size at the given floor and 
    # offset.
    def can_place?(floor, offset, size)
      # Check this is within the bounds of the mall
      return false if offset + size > Mall::SLOTS_PER_FLOOR
      return false if offset < 0
      return false if floor >= floors
      return false if floor < 0

      # Check no units on the same floor overlap with this
      slots_occupied_this = (offset...(offset + size)).to_a
      units.each do |unit|
        next if unit.floor != floor
        return false if (slots_occupied_this & unit.slots_occupied).any?
      end

      true
    end
  end
end
