module GosuGameJam3
  class Customer < Entity
    module Intent
      Browse = Struct.new('Browse')
    end

    module Action
      WalkTo = Struct.new('WalkTo', :offset)
      Leave = Struct.new('Leave')
      LookAroundUnit = Struct.new('LookAroundUnit', :subactions)
    end

    class Preferences
      class Budget
        Discount = new
        Intermediate = new
        HighEnd = new
        Any = new
  
        def distance(other)
          return 0 if self == Any || other == Any
  
          {
            Discount => {
              Discount => 0,
              Intermediate => 1,
              HighEnd => 2,
            },
            Intermediate => {
              Discount => 1,
              Intermediate => 0,
              HighEnd => 1,
            },
            HighEnd => {
              Discount => 2,
              Intermediate => 1,
              HighEnd => 0,
            },
          }[self][other]
        end
      end
  
      class Department
        Fashion = new
        Technology = new
      end
  
      # This shopper's budget, which will influence the units they enter.
      attr_accessor :budget
  
      # An array of departments which this customer would visit.
      attr_accessor :interests
    end  

    def initialize(intent:, preferences:, **kw)
      @base_intent = intent
      @immediate_intent = nil
      @actions = [] 
      @speed = 1.5
      @preferences = preferences
      @considered_units = []

      super(**kw)
    end

    # Why the customer entered the mall in the first place. If this is an activity which can be
    # completed (e.g. get some food), they'll leave when it's completed. This doesn't change during
    # their visit.
    attr_accessor :base_intent

    # What the customer needs to actively do. These are much more granular than intents, instead
    # describing actions such as "move here". Actions form a queue, with items being shifted as they
    # are completed. `#tick` acts on the first item in the queue.
    attr_accessor :actions

    # This customer's walking speed, in pixels per tick.
    attr_accessor :speed

    # This customer's shopping preferences. These do not change during their visit.
    attr_accessor :preferences

    # The units which this customer has already visited, or considered and decided not to visit.
    attr_accessor :considered_units

    def draw
      Gosu.draw_rect(
        position.x, position.y, 15, 30,
        in_store? ? Gosu::Color.new(255, 160, 0, 0) : Gosu::Color.new(255, 255, 0, 0)
      )
    end

    def in_store?
      actions.first.is_a?(Action::LookAroundUnit)
    end

    def tick
      decide_next_action if actions.empty?

      # TODO: handle nil case
      if (floor, offset = $mall.point_to_slot(position))
        unit = $mall.unit_at(floor, offset)
        action = actions.first
        case action
        when Action::WalkTo
          if action.offset == offset
            # We've reached our destination!
            actions.shift
          elsif action.offset > offset
            # We need to move right
            self.position.x += speed
          elsif action.offset < offset
            # We need to move left
            self.position.x -= speed
          end

        when Action::LookAroundUnit
          # Generate a list of subactions, if we've just moved into this item in the queue
          if action.subactions == nil
            action.subactions = []
            (rand(2..3) * 2).times do |i|
              if i.even?
                # Pick a random point within the unit to move to
                point = (unit.position.x..(unit.position.x + unit.size * Mall::SLOT_WIDTH)).to_a.sample
                action.subactions << [:move, point]
              else
                # Wait for a random amount of time
                action.subactions << [:wait, (20..200).to_a.sample]
              end
            end

            # Finish by moving back to the X we started at
            action.subactions << [:move, position.x]
          end

          # Act on the current subaction
          task, value = action.subactions.first
          case task
          when :move
            if (position.x - value).abs < speed * 2
              action.subactions.shift
            elsif value > position.x
              position.x += speed
            elsif value < position.x
              position.x -= speed
            end
          when :wait
            action.subactions.first[1] -= 1 
            action.subactions.shift if value <= 0
          end

          # If we've completed all subactions, shift the action
          actions.shift if action.subactions.empty?
          
        when Action::Leave
          if (position.x - $mall.slot_to_point(floor: 0, offset: 0).x).abs < speed * 2
            # If we've reached the end, delete ourselves
            $mall.customers.delete(self)
          else
            # Keep moving
            position.x -= speed
          end
          
        end
      end
    end

    # If the `#actions` queue is empty, randomly decide on what to do next based on the customer's
    # shopping preferences.
    def decide_next_action
      $mall.units.each do |unit|
        next if considered_units.include?(unit)

        if rand < chance_to_enter(unit)
          raise 'multiple floors nyi' if unit.floor > 0 # TODO
          actions << Action::WalkTo.new(unit.doorway_offset)
          actions << Action::LookAroundUnit.new
          considered_units << unit
          break
        else
          considered_units << unit
        end
      end

      # We didn't find anything to do - time to leave!
      # TODO: when multiple floors, we need to go to the bottom one first
      actions << Action::Leave.new
    end

    # Given a unit, returns a chance (as a ratio) that this customer would choose to enter it.
    def chance_to_enter(unit)
      # Customers will never enter units which are two steps out of their budget preferences, and
      # be less likely to visit units which are one unit out
      budget_multiplier = {
        0 => 1,
        1 => 0.7,
        2 => 0,
      }[unit.budget.distance(preferences.budget)]

      # Customers will only visit units they're interested in
      interest_multiplier = (unit.departments & preferences.interests).any? ? 1 : 0

      1 * budget_multiplier * interest_multiplier
    end
  end
end
