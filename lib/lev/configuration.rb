module Lev
  class Configuration
    attr_accessor :raise_fatal_errors

    def initialize
      @raise_fatal_errors = false
    end
  end
end
