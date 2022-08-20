require_relative 'unit'
require_relative '../customer'

module GosuGameJam3
  module Units
    D = Customer::Preferences::Department
    B = Customer::Preferences::Budget

    class DesignerClothes < Unit
      derive_unit([D::Fashion], B::HighEnd, 1500, 0.3, 100..600)
    end
    class DiscountClothes < Unit
      derive_unit([D::Fashion], B::Discount, 800, 0.9, 10..30)
    end
    class Shoes < Unit
      derive_unit([D::Fashion], B::Intermediate, 500, 0.4, 40..80)
    end

    class HighEndTechnology < Unit
      derive_unit([D::Technology], B::HighEnd, 1500, 0.1, 500..2000)
    end
    class UsedTechnology < Unit
      derive_unit([D::Technology], B::Intermediate, 600, 0.4, 20..150)
    end
    class PhoneCases < Unit
      derive_unit([D::Technology], B::Discount, 300, 0.9, 5..10)
    end

    class GeneralToys < Unit
      derive_unit([D::Toys], B::Discount, 800, 0.6, 10..50)
    end
    class BuildingBlockToys < Unit
      derive_unit([D::Toys], B::HighEnd, 1300, 0.5, 50..200)
    end
    class VideoGames < Unit
      derive_unit([D::Toys], B::Intermediate, 600, 0.7, 10..50)
    end

    class Pharmacy < Unit
      derive_unit([D::Health], B::Discount, 500, 0.9, 1..5)
    end
    class Cosmetics < Unit
      derive_unit([D::Health], B::Intermediate, 800, 0.5, 10..50)
    end
    class LuxurySoap < Unit
      derive_unit([D::Health], B::HighEnd, 1000, 0.6, 20..60)
    end

    class Bakery < Unit
      derive_unit([D::Food], B::Discount, 400, 0.7, 1..4)
    end
    class Donuts < Unit
      derive_unit([D::Food], B::Intermediate, 400, 0.9, 1..2)
    end
    class FineDining < Unit
      derive_unit([D::Food], B::HighEnd, 1600, 0.4, 50..100)
    end

    class Elevator < Unit
      derive_unit([D::Special], B::Any, 200, 0, 0..0)
    end
  end
end
