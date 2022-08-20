module GosuGameJam3
  module Utils
    def self.format_money(money)
      "$#{money.to_s.chars.reverse.each_slice(3).map(&:join).join(",").reverse}"
    end
  end
end

# From marcandre/backports
unless Enumerable.method_defined? :tally
  module Enumerable
    def tally
      h = {}
      # NB: By spec, tally should return default-less hash
      each_entry { |item| h[item] = h.fetch(item, 0) + 1 }

      h
    end
  end
end
