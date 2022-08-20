module GosuGameJam3
  # The overall game state.
  # There is one instance of this class, accessible with `$mall`.
  class Mall
    SLOT_WIDTH = 50
    SLOTS_PER_FLOOR = 30
    FLOOR_HEIGHT = 160
    BOTTOM_FLOOR_Y = 550
    FLOOR_PADDING = 10

    MAX_FLOORS = 4
    FLOOR_UPGRADE_COSTS = {
      1 => 3000,
      2 => 5000,
      3 => 7000,
    }
    
    def initialize
      @floors = 1
      @units = []
      @customers = []
      @misc_entities = []
      @sentiments = []
      @popularity = 100
      @interest_reputation = Customer::Preferences::Department.all.map { |i| [i, 10.0] }.to_h
      @budget_reputation = Customer::Preferences::Budget.all.map { |i| [i, 10.0] }.to_h
      @money = ENV['BIG_MONEY'] ? 1000000000 : 2500

      @ticks_until_next_customer = 500
      @ticks = 0
    end

    # The number of floors the mall has.
    attr_accessor :floors

    # All of the units in the mall.
    attr_accessor :units

    # The customers in the mall.
    attr_accessor :customers

    # Miscallenous entities which the mall will draw and tick.
    attr_accessor :misc_entities

    # The overall popularity of the mall, acting as a global multiplier to the number of customers
    # who visit.
    attr_accessor :popularity

    # The relative popularity of this mall for people with particular interests. Customers will be
    # more likely to have interests with a higher reputation.
    # A hash of { interest => reputation }. The reputation values do not add up to 1 or anything
    # like that!
    attr_accessor :interest_reputation

    # The relative popularity of this mall for people with particular budgets. Same format as 
    # `interest_reputation`.
    attr_accessor :budget_reputation

    # The amount of money the player has.
    attr_accessor :money

    # The time since the game started, in ticks.
    attr_accessor :ticks

    # An array of customer sentiments about the mall.
    attr_accessor :sentiments

    def add_sentiment(kind, message)
      sentiments << Customer::Sentiment.new(kind, message, ticks)
    end
    def add_positive_sentiment(message); add_sentiment(:positive, message); end
    def add_negative_sentiment(message); add_sentiment(:negative, message); end

    def draw
      # Draw background
      padding = (WIDTH - (SLOT_WIDTH * SLOTS_PER_FLOOR)) / 2
      Gosu.draw_rect(
        padding, BOTTOM_FLOOR_Y + FLOOR_HEIGHT - ((FLOOR_HEIGHT + FLOOR_PADDING) * floors),
        WIDTH - padding * 2, (FLOOR_HEIGHT + FLOOR_PADDING) * floors,
        Gosu::Color.new(255, 227, 227, 227),
      )

      # Draw ground
      Gosu.draw_rect(
        0, BOTTOM_FLOOR_Y + FLOOR_HEIGHT,
        WIDTH, 50,
        Gosu::Color.new(255, 40, 40, 40),
      )

      # Draw floor separators
      (floors - 1).times do |i|
        Gosu.draw_rect(
          padding, BOTTOM_FLOOR_Y - (FLOOR_HEIGHT + FLOOR_PADDING) * i - FLOOR_PADDING,
          WIDTH - padding * 2, FLOOR_PADDING,
          Gosu::Color.new(255, 40, 40, 40),
        )
      end

      # Draw walls
      Gosu.draw_rect(
        padding - FLOOR_PADDING, BOTTOM_FLOOR_Y - ((FLOOR_HEIGHT + FLOOR_PADDING) * (floors - 1)),
        FLOOR_PADDING, (FLOOR_HEIGHT + FLOOR_PADDING) * floors,
        Gosu::Color.new(255, 40, 40, 40),
      )
      Gosu.draw_rect(
        WIDTH - padding, BOTTOM_FLOOR_Y - ((FLOOR_HEIGHT + FLOOR_PADDING) * (floors - 1)),
        FLOOR_PADDING, (FLOOR_HEIGHT + FLOOR_PADDING) * floors,
        Gosu::Color.new(255, 40, 40, 40),
      )

      # Draw ceiling
      Gosu.draw_rect(
        padding - FLOOR_PADDING, BOTTOM_FLOOR_Y - ((FLOOR_HEIGHT + FLOOR_PADDING) * (floors - 1)) - FLOOR_PADDING,
        WIDTH - (padding - FLOOR_PADDING) * 2, FLOOR_PADDING,
        Gosu::Color.new(255, 40, 40, 40),
      )

      # Draw units and customers
      units.each(&:draw_bg)
      customers.filter(&:in_store?).each(&:draw)
      units.each(&:draw_fg)
      customers.reject(&:in_store?).each(&:draw)

      # Draw other entities
      misc_entities.each(&:draw)
    end

    def tick
      customers.each(&:tick)

      @ticks_until_next_customer -= 1
      if @ticks_until_next_customer <= 0
        customers << Customer.generate
        @ticks_until_next_customer = (1.0 / popularity) * 5000 * rand(0.5..1.5)
      end

      # Tick other entities
      misc_entities.each(&:tick)
      self.ticks += 1
    end

    # Maps a floor and offset into an engine point where the unit should be located.
    def slot_to_point(floor:, offset:)
      padding = (WIDTH - (SLOT_WIDTH * SLOTS_PER_FLOOR)) / 2
      
      Point.new(padding + SLOT_WIDTH * offset, BOTTOM_FLOOR_Y - (FLOOR_HEIGHT + FLOOR_PADDING) * floor)
    end

    # Maps a point to a floor and offset. Returns [floor, offset], or nil if the cursor is not on a
    # slot.
    def point_to_slot(point)
      padding = (WIDTH - (SLOT_WIDTH * SLOTS_PER_FLOOR)) / 2

      floor = (BOTTOM_FLOOR_Y - point.y) / (FLOOR_HEIGHT + FLOOR_PADDING) + 1
      return nil if floor < 0 || floor >= floors

      offset = (point.x - padding) / SLOT_WIDTH
      return nil if offset < 0 || offset >= SLOTS_PER_FLOOR

      [floor, offset.floor]
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

    # Returns the unit which overlaps with the given floor and offset, if any.
    def unit_at(floor, offset)
      units.find do |unit|
        unit.floor == floor && unit.slots_occupied.include?(offset)
      end
    end

    # Pathfinds from one floor and offset to another, using one elevator shaft if required.
    # 
    # Returns one of the following:
    #   - :same, if the locations are on the same floor.
    #   - an offset, the location of an elevator, if an elevator is required and exists to
    #       traverse from the current to destination floor.
    #   - nil, if it is not possible to traverse to the destination using one elevator shaft.
    def pathfind(from_floor, from_offset, to_floor, to_offset)
      # Are we on the right floor already? If so, this is easy
      return :same if from_floor == to_floor
        
      # Find the closest elevator on this floor which can take us to our floor
      closest_elevator = units
        .filter { |u| u.is_a?(Units::Elevator) && u.floor == from_floor && elevator_floors_reachable(u).include?(to_floor) }
        .min_by { |u| (u.offset - from_offset).abs }
      return nil if closest_elevator.nil?

      closest_elevator.offset
    end

    def elevator_floors_reachable(unit)
      units
        .filter { |u| u.is_a?(Units::Elevator) && u.offset == unit.offset }
        .map(&:floor)
    end
  end
end
