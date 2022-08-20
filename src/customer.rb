require_relative 'ui/floating_text'

module GosuGameJam3
  class Customer < Entity
    HEIGHT = 30
    VARIANTS = 1

    module Intent
      Browse = Struct.new('Browse')
    end

    module Action
      WalkTo = Struct.new('WalkTo', :offset)
      Leave = Struct.new('Leave')
      LookAroundUnit = Struct.new('LookAroundUnit', :subactions)
      TakeElevator = Struct.new('TakeElevator', :floor, :ticks)
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

        def self.all
          [Discount, Intermediate, HighEnd]
        end
      end
  
      class Department
        def initialize(name)
          @name = name
        end
        attr_reader :name

        Fashion = new("fashion")
        Technology = new("technology")
        Toys = new("toys and games")
        Health = new("health and beauty")
        Food  = new("food")

        # Assigned only to utilities like elevators
        Special = new("???")
          
        def self.all
          [Fashion, Technology, Toys, Health, Food]
        end
      end

      def initialize(budget:, interests:)
        @budget = budget
        @interests = interests
      end
  
      # This shopper's budget, which will influence the units they enter.
      attr_accessor :budget
  
      # An array of departments which this customer would visit.
      attr_accessor :interests
    end  

    Sentiment = Struct.new('Sentiment', :kind, :message, :ticks)

    def initialize(variant:, intent:, preferences:, **kw)
      @base_intent = intent
      @immediate_intent = nil
      @actions = [] 
      @speed = 1.5
      @preferences = preferences
      @considered_units = []
      @visited_units = []
      @has_done_anything = false

      super(animations: {
        walk: Animation.new([
          Res.image("customers/var#{variant}/stage1.png"),
          Res.image("customers/var#{variant}/stage2.png"),
          Res.image("customers/var#{variant}/stage3.png"),
          Res.image("customers/var#{variant}/stage4.png"),
        ], 8),
        idle: Animation.static(Res.image("customers/var#{variant}/idle.png"))
      }, **kw)
    end

    def draw_centred?
      false
    end

    # Randomly generates and returns a new customer, based on the kind of customers which the mall
    # attracts.
    def self.generate
      weighted_sample = ->hash do
        total = hash.values.sum
        cumulative = 0.0
        value_lookup = hash.to_a.map do |this_value, this_weight|
          entry = [cumulative..(cumulative + this_weight), this_value]
          cumulative += this_weight
          entry
        end

        random_value = rand(0.0..total)
        value_lookup.find { |(range, _)| range.include?(random_value) }[1]
      end

      new(
        intent: Intent::Browse,
        preferences: Preferences.new(
          budget: weighted_sample.($mall.budget_reputation),
          interests: rand(1..3).times.map { weighted_sample.($mall.interest_reputation) }.uniq,
        ),
        position: $mall.slot_to_point(floor: 0, offset: 0) + Point.new(0, Mall::FLOOR_HEIGHT - HEIGHT),
        variant: rand(0..(VARIANTS - 1)) + 1,
      )
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

    # The units which this customer has already visited. A subset of `considered_units`.
    attr_accessor :visited_units

    # Whether this customer has done anything. Even if they visit with no relevant interests,
    # they'll always do something before they leave - even just walking to a random unit
    attr_accessor :has_done_anything

    def in_store?
      actions.first.is_a?(Action::LookAroundUnit)
    end

    def tick
      super
      decide_next_action if actions.empty?

      # TODO: handle nil case
      if (floor, offset = $mall.point_to_slot(position))
        unit = $mall.unit_at(floor, offset)
        action = actions.first
        case action
        when Action::WalkTo
          self.animation = :walk
          if action.offset == offset
            # We've reached our destination!
            actions.shift
          elsif action.offset > offset
            # We need to move right
            self.mirror_x = false
            self.position.x += speed
          elsif action.offset < offset
            # We need to move left
            self.mirror_x = true
            self.position.x -= speed
          end

        when Action::LookAroundUnit
          if unit.nil?
            actions.shift
            return
          end

          # Generate a list of subactions, if we've just moved into this item in the queue
          if action.subactions == nil
            action.subactions = []
            (rand(2..3) * 2).times do |i|
              if i.even?
                # Pick a random point within the unit to move to
                point = (unit.position.x..(unit.position.x + unit.size * Mall::SLOT_WIDTH - 20)).to_a.sample
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
            self.animation = :walk
            if (position.x - value).abs < speed * 2
              action.subactions.shift
            elsif value > position.x
              self.mirror_x = false
              position.x += speed
            elsif value < position.x
              self.mirror_x = true
              position.x -= speed
            end
          when :wait
            self.animation = :idle
            action.subactions.first[1] -= 1 
            action.subactions.shift if value <= 0
          end

          # If we've completed all subactions...
          if action.subactions.empty?
            # Decide whether we're going to buy something
            if rand < unit.purchase_chance
              # Yep! Decide on a value, add to money, and create a little text thing
              value = unit.purchase_range.to_a.sample
              $mall.money += value

              $mall.misc_entities << FloatingText.new(
                text: Utils.format_money(value),
                colour: Gosu::Color.rgb(0, 225, 50),
                position: self.position + Point.new(0, -15)
              )
            end

            # Shift the action to do something else
            actions.shift 
          end
          
        when Action::Leave
          if (position.x - $mall.slot_to_point(floor: 0, offset: 0).x).abs < speed * 2
            # If we've reached the end, delete ourselves
            $mall.customers.delete(self)
          else
            # Keep moving
            self.animation = :walk
            self.mirror_x = true
            position.x -= speed
          end

        when Action::TakeElevator
          self.animation = :idle
          if action.ticks == 30
            diff = action.floor - floor
            position.y -= diff * (Mall::FLOOR_HEIGHT + Mall::FLOOR_PADDING)
          elsif action.ticks == 0
            self.opacity = 1
            actions.shift
          elsif action.ticks < 30
            self.opacity = 1 - (action.ticks.to_f / 30)
          elsif action.ticks < 60
            self.opacity = (action.ticks.to_f - 30) / 30
          end

          action.ticks -= 1
          
        end
      else
        puts "Warning: Customer at #{position} is out of bounds, deleting"
        $mall.customers.delete(self)
      end
    end

    # If the `#actions` queue is empty, randomly decide on what to do next based on the customer's
    # shopping preferences.
    def decide_next_action
      $mall.units.each do |unit|
        next if considered_units.include?(unit)

        if rand < chance_to_enter(unit)
          considered_units << unit
          if (floor, offset = $mall.point_to_slot(position))
            path_result = $mall.pathfind(floor, offset, unit.floor, unit.offset)
            if path_result == :same
              actions << Action::WalkTo.new(unit.doorway_offset)
            elsif path_result.nil?
              $mall.add_negative_sentiment("I can't reach the #{unit.departments.first.name} store!")
              redo
            else
              actions << Action::WalkTo.new(path_result)
              actions << Action::TakeElevator.new(unit.floor, 60)
              actions << Action::WalkTo.new(unit.doorway_offset)
            end
            actions << Action::LookAroundUnit.new

            visited_units << unit
            self.has_done_anything = true
          end
          return
        else
          considered_units << unit
        end
      end

      # We didn't find anything to do - time to leave!
      # (Unless we haven't done anything at all - in which case, walk across the floor, so that
      # we don't instantly phase out of existence)
      if !has_done_anything
        actions << Action::WalkTo.new(rand((Mall::SLOTS_PER_FLOOR - 5)...Mall::SLOTS_PER_FLOOR))
        self.has_done_anything = true

        budget = {
          Preferences::Budget::Discount => "discount ",
          Preferences::Budget::HighEnd => "high-end ",
        }[preferences.budget] || ""

        preferences.interests.each do |i|
          $mall.add_negative_sentiment("I wish there were more #{budget}#{i.name} stores here.")
        end
      else
        if visited_units.any?
          most_visited_dept, visits = visited_units.flat_map(&:departments).tally.max_by { |_, v| v }
          if visits > 1
            $mall.add_positive_sentiment("I love all of the #{most_visited_dept.name} stores here!")
          else
            $mall.add_positive_sentiment("The #{most_visited_dept.name} store here is great!")
          end
        end

        # Time to properly leave - go to the far left of the bottom floor
        if (floor, offset = $mall.point_to_slot(position))
          path_result = $mall.pathfind(floor, offset, 0, 0)
          if path_result.is_a?(Integer)
            actions << Action::WalkTo.new(path_result)
            actions << Action::TakeElevator.new(0, 60)
          end
        end
        actions << Action::Leave.new
      end
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
