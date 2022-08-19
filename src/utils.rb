module GosuGameJam3
  module Utils
    def self.format_money(money)
      "$#{money.to_s.chars.reverse.each_slice(3).map(&:join).join(",").reverse}"
    end
  end
end
