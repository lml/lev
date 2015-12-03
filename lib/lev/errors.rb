require 'lev/errors/error'

module Lev
  class Errors < Array
    def initialize(raise_fatal_errors = false)
      @raise_fatal_errors = raise_fatal_errors
    end

    def add(args = {})
      args.stringify_keys!

      failing = args.delete('fail')
      error = Error.new(args)

      if failing && raise_fatal_errors
        raise FatalError, error.to_s
      else
        push(error.to_s)
      end
    end

    private
    attr_reader :raise_fatal_errors
  end

  class FatalError < StandardError; end
end
