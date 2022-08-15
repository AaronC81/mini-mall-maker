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
      # TODO: temporary, only needed during development
      if image[0].width != image[1].width || image[0].height != image[1].height
        raise "size mismatch between fg and bg (#{self.name})"
      end

      image[0].width / Mall::SLOT_WIDTH
    end

    # The departments which this store has. Abstract: must be overridden by a derived class.
    def self.departments
      raise 'abstract'
    end

    # The budget which this store caters to. Abstract: must be overridden by a derived class.
    def self.budget
      raise 'abstract'
    end

    # A convenience method to define `.departments` and `.budget`.
    def self.derive_unit(_departments, _budget)
      self.class_eval do
        define_method(:departments) { _departments }
        define_method(:budget) { _budget }
      end 
    end
    
    def draw_fg
      image[0].draw(
        position.x,
        position.y,
      )
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
  end
end
