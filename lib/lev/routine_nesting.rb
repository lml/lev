module Lev

  # Manages running of routines inside other routines.  In the Lev context, 
  # Handlers and Algorithms are routines.  A routine and any routines nested
  # inside of it are executed within a single transaction, or depending on the
  # requirements of all the routines, no transaction at all.
  #
  # Classes that include this module get:
  #
  #  1) a "run" method for running nested routines in a standardized way.
  #     Routines executed through the run method get hooked into the calling
  #     hierarchy.
  # 
  #  2) a "runner" accessor which points to the routine which called it. If
  #     runner is nil that means that no other routine called it (some other 
  #     code did)
  # 
  #  3) a "topmost_runner" which points to the highest routine in the calling
  #     hierarchy (that routine whose 'runner' is nil)
  #
  # Classes that include this module must:
  #
  #  1) supply a "call" instance method (def call(*args, &block)) that passes
  #     its arguments and block to whatever code inside the class does the work
  #     of the class
  #
  # Classes that include this module may:
  #
  #  1) Call the class-level "uses_routine" method to indicate which other 
  #     routines will be run.  Helps set isolation levels, etc.  When this
  #     method is used, the provided routine may
  #  
  #  2) Set a default transaction isolation level by declaring a class method
  #     named "default_transaction_isolation" that returns an instance of 
  #     Lev::TransactionIsolation
  #   
  #
  module RoutineNesting

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      
      # Called at a routine's class level to foretell which other routines will
      # be used when this routine executes.  Helpful for figuring out ahead of
      # time what kind of transaction isolation level should be used.
      def uses_routine(routine_class, options={})
        symbol = options[:as] || routine_class.name.underscore.gsub('/','_').to_sym

        raise IllegalArgument, "Routine #{routine_class} has already been registered" \
          if nested_routines[symbol]

        nested_routines[symbol] = routine_class

        transaction_isolation.replace_if_more_isolated(routine_class.transaction_isolation)
      end

      def transaction_isolation
        @transaction_isolation ||= default_transaction_isolation
      end

      def default_transaction_isolation
        TransactionIsolation.no_transaction 
      end

      def nested_routines
        @nested_routines ||= {}
      end

    end

    def in_transaction(options={}) 
      if self != topmost_runner || self.class.transaction_isolation == TransactionIsolation.no_transaction
        yield
      else
        ActiveRecord::Base.isolation_level( self.class.transaction_isolation.symbol ) do
          ActiveRecord::Base.transaction { yield }
        end
      end
    end

    def run(other_routine, *args, &block)
      if other_routine.is_a? Symbol
        nested_routine = self.class.nested_routines[other_routine]
        if nested_routine.nil?
          raise IllegalArgument, 
                "Routine symbol #{other_routine} does not point to a registered routine"
        end
        other_routine = nested_routine
      end

      other_routine = other_routine.new if other_routine.is_a? Class

      included_modules = other_routine.eigenclass.included_modules

      raise IllegalArgument, "Can only run another nested routine" \
        if !(included_modules.include? Lev::RoutineNesting)

      other_routine.runner = self
      other_routine.call(*args, &block)
    end

    attr_reader :runner

  protected

    attr_writer :runner

    def topmost_runner
      runner.nil? ? self : runner.topmost_runner
    end

    def runner=(runner)
      @runner = runner

      if topmost_runner.class.transaction_isolation.weaker_than(self.class.default_transaction_isolation)
        raise IsolationMismatch, 
              "The routine being run has a stronger isolation requirement than " + 
              "the isolation being used by the routine(s) running it; call the " +
              "'uses' method in the running routine's initializer"
      end
    end

  end
end