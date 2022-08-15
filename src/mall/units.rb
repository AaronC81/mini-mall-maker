require_relative 'unit'
require_relative '../customer'

module GosuGameJam3
  module Units
    D = Customer::Preferences::Department
    B = Customer::Preferences::Budget

    class DesignerClothes < Unit
      derive_unit([D::Fashion], B::HighEnd)
    end
    class DiscountClothes < Unit
      derive_unit([D::Fashion], B::Discount)
    end
    class HighEndTechnology < Unit
      derive_unit([D::Technology], B::HighEnd)
    end
  end
end
