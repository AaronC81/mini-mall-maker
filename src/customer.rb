module GosuGameJam3
  class Customer < Entity
    module Intent
      Browse = Struct.new('Browse')
    end

    module Action
      WalkTo = Struct.new('WalkTo', :offset, :pixels)
      LookAroundUnit = Struct.new('LookAroundUnit', :subactions)
    end

    def initialize(intent:, **kw)
      @base_intent = intent
      @immediate_intent = nil

      # TODO
      @actions = [
        Action::WalkTo.new($mall.units.sample.doorway_offset),
        Action::LookAroundUnit.new,
        Action::WalkTo.new(0),
      ] 

      @speed = 1.5

      super(**kw)
    end

    # Why the customer entered the mall in the first place. If this is an activity which can be
    # completed (e.g. get some food), they'll leave when it's completed. This doesn't change during
    # their visit.
    attr_accessor :base_intent

    # The customer's immediate intent, if any. The immediate intent is always completable, and
    # overrides the base intent to determine their behaviour. Customers may randomly get immediate
    # intents while in the mall - for example, while browsing as their base intent, they may
    # randomly gain the immediate intent to get some food. Once this immediate intent is complete,
    # they'll revert to their base intent.
    attr_accessor :immediate_intent

    # What the customer needs to actively do. These are much more granular than intents, instead
    # describing actions such as "move here". Actions form a queue, with items being shifted as they
    # are completed. `#tick` acts on the first item in the queue.
    attr_accessor :actions

    # This customer's walking speed, in pixels per tick.
    attr_accessor :speed

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
        end
      end
    end
  end
end
