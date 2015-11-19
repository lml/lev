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

    def call
      ActiveRecord::Base.transaction { exec }
    end

    def run(routine_name, *args)
      self.class.nested_routines[routine_name].call(*args)
    end

    def fatal_error(args = {})
      errors.add(args.merge(fail: true))
    end

    module ClassMethods
      def call; new.call; end

      def uses_routine(routine, options = {})
        key = routine.name.underscore.gsub('/','_').to_sym
        nested_routines[key] = {
          routine_class: routine,
          options: options
        }
      end

      def raise_fatal_errors?
        @raise_fatal_errors || (Lev.configuration.raise_fatal_errors &&
                                  @raise_fatal_errors.nil?)
      end

      private
      def nested_routines
        @nested_routines ||= {}
      end
    end
  end
end
