module Lev
  class RedisStore

    def initialize(*args)
      @redis_store = Redis::Store.new(*args)
    end

    def fetch(key)
      @redis_store.get(key)
    end

    def write(key, value)
      @redis_store.set(key, value)
    end

  end
end
