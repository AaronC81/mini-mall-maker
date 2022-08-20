require_relative '../engine/entity'
require_relative '../ui/tooltip'

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

    # The offset where the doorway of this unit is located.
    # (As opposed to the start of the building, like `offset`.)
    def doorway_offset
      offset + size / 2
    end

    # Accessors for static methods
    def size; self.class.size; end
    def image; self.class.image; end
    def departments; self.class.departments; end
    def budget; self.class.budget; end
    def purchase_chance; self.class.purchase_chance; end
    def purchase_range; self.class.purchase_range; end
    def unit_name; self.class.unit_name; end
    
    # The images of this unit. This is derived from the class' name, by converting it into snake
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
  
      [Res.image("units/#{image_name}_fg.png"), Res.image("units/#{image_name}_bg.png")]
    end

    # The number of slots this unit occupies, calculated from its image.
    def self.size
      image[0].width / Mall::SLOT_WIDTH
    end

    # The departments which this store has. Abstract: must be overridden by a derived class.
    def self.departments; raise 'abstract'; end

    # The budget which this store caters to. Abstract: must be overridden by a derived class.
    def self.budget; raise 'abstract'; end

    # The cost of building this store.
    def self.build_cost; raise 'abstract'; end 

    # The chance, as a ratio, that a customer will buy something from this unit after entering.
    def self.purchase_chance; raise 'abstract'; end

    # The range of prices which a customer may pay when buying something from this unit. 
    def self.purchase_range; raise 'abstract'; end

    # The name of this unit.
    def self.unit_name; raise 'abstract'; end

    # A convenience method to define properties of this unit.
    def self.derive_unit(_name, _departments, _budget, _build_cost, _purchase_chance, _purchase_range)
      define_singleton_method(:unit_name) { _name }
      define_singleton_method(:departments) { _departments }
      define_singleton_method(:budget) { _budget }
      define_singleton_method(:build_cost) { _build_cost }
      define_singleton_method(:purchase_chance) { _purchase_chance }
      define_singleton_method(:purchase_range) { _purchase_range }
    end
  
    # A convenience method to define that a unit doesn't have an image yet.
    def self.image_todo
      define_method(:draw_fg) {}
      define_singleton_method(:size) { 1 }
      define_method(:draw_bg) do
        Gosu.draw_rect(position.x, position.y, Mall::SLOT_WIDTH, Mall::FLOOR_HEIGHT, Gosu::Color::RED)
      end 
    end
    
    def draw_fg
      image[0].draw(
        position.x,
        position.y,
      )
      draw_tooltip
    end

    def draw_bg
      image[1].draw(
        position.x,
        position.y,
      )
    end

    # Returns an array of the slot indexes on this floor occupied by this unit.
    def slots_occupied
      (offset...(offset + size)).to_a
    end

    # Tooltip implementation
    include Tooltip
    def width; size * Mall::SLOT_WIDTH; end
    def height; Mall::FLOOR_HEIGHT; end
    def tooltip; unit_name; end
  end
end
