module Lev
  module Stores
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

      def clear
        @store.clear
      end
    end
  end
end
