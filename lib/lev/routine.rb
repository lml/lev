require 'lev/errors'

module Lev
  module Routine
    attr_accessor :errors

    def self.included(base)
      base.extend ClassMethods
    end

    def initialize
      @errors = Errors.new(self.class.raise_fatal_errors?)
    end

    def call; exec; end

    def fatal_error(args = {})
      errors.add(args.merge(fail: true))
    end

    module ClassMethods
      def call; new.call; end

      def raise_fatal_errors?
        @raise_fatal_errors || (Lev.configuration.raise_fatal_errors &&
                                  @raise_fatal_errors.nil?)
      end
    end
  end
end
