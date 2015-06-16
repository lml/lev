module Lev
  class MemoryStore

    def initialize
      @store = {}
    end

    def fetch(key)
      @store[key]
    end

    def write(key, value)
      @store[key] = value
    end

  end
end
