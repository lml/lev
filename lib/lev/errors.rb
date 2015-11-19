require 'lev/error'

module Lev
  class Errors < Array
    def initialize(raise_fatal_errors = false)
      @raise_fatal_errors = raise_fatal_errors
    end

    def add(args = {})
      args[:kind] ||= :lev
      failing = args.delete(:fail)

      if failing && raise_fatal_errors
        raise FatalError, args.to_a.map { |i| i.join(' ') }.join(' - ')
      end
    end

    private
    attr_reader :raise_fatal_errors
  end

  class FatalError < StandardError; end
end
