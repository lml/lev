module Lev
  module Utilities

    def self.deep_merge(hash, override_hash)
      result = hash.dup
      override_hash.each_pair do |k,v|
        tv = result[k]
        result[k] = tv.is_a?(Hash) && v.is_a?(Hash) ? deep_merge(tv, v) : v
      end
      result
    end

  end
end

module Kernel
  def eigenclass
    class << self
      self
    end
  end

  def includes_module?(mod)
    eigenclass.included_modules.include?(mod)
  end
end
