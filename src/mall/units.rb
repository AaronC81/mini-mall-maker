require_relative 'unit'
require_relative '../customer'

module GosuGameJam3
  module Units
    D = Customer::Preferences::Department
    B = Customer::Preferences::Budget

    class DesignerClothes < Unit
      derive_unit([D::Fashion], B::HighEnd, 20000, 0.1, 100..600)
    end
    class DiscountClothes < Unit
      derive_unit([D::Fashion], B::Discount, 2500, 0.7, 10..30)
    end
    class HighEndTechnology < Unit
      derive_unit([D::Technology], B::HighEnd, 12000, 0.025, 500..2000)
    end
  end
end
