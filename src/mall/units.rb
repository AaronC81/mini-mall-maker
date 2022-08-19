require_relative 'unit'
require_relative '../customer'

module GosuGameJam3
  module Units
    D = Customer::Preferences::Department
    B = Customer::Preferences::Budget

    class DesignerClothes < Unit
      derive_unit([D::Fashion], B::HighEnd, 20000)
    end
    class DiscountClothes < Unit
      derive_unit([D::Fashion], B::Discount, 2500)
    end
    class HighEndTechnology < Unit
      derive_unit([D::Technology], B::HighEnd, 7500)
    end
  end
end
