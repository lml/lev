module Lev
  
  # A "routine" in the Lev world is a piece of code that is responsible for
  # doing one thing, normally acting on one or more other objects.  Routines
  # are particularly useful when the thing that needs to be done involves 
  # making changes to multiple other objects.  In an OO/MVC world, an operation
  # that involves multiple objects might be implemented by spreading that logic
  # among those objects.  However, that leads to classes having more
  # responsibilities than they should (and more knowlege of other classes than
  # they should) as well as making the code hard to follow.
  #
  # Routines typically don't have any persistent state that is used over and 
  # over again; they are created, used, and forgotten.  A routine is a glorified
  # function with a special single-responsibility purpose.
  #
  # Routines can be nested -- there is built-in functionality for calling
  # one routine inside another.
  #
  # A class becomes a routine by adding:
  #
  #   include Lev::Routine
  #
  # in its definition.
  #
  # Other than that, all a routine has to do is implement an "exec" method 
  # that takes arbitrary arguments and that adds errors to an internal
  # array-like "errors" object and results to a "results" hash.
  #
  # A routine will automatically get both class- and instance-level "call"
  # methods that take the same arguments as the "exec" method.  The class-level
  # call method simply instantiates a new instance of the routine and calls 
  # the instance-level call method (side note here is that this means that 
  # routines aren't typically instantiated with state).
  # 
  # A routine is automatically run within a transaction.  The isolation level
  # of the routine can be set by overriding the "default_transaction_isolation"
  # class method and having it return an instance of Lev::TransactionIsolation.
  # This is also how routines can be set to not be run in a transaction.
  #
  # As mentioned above, routines can call other routines.  While this is of
  # course possible just by calling the other routine's call method directly,
  # it is strongly recommended that one routine call another routine using the
  # provided "run" method.  This method takes the name of the routine class 
  # and the arguments/block it expects in its call/exec methods.  By using the
  # run method, the called routine will be hooked into the common error and 
  # transaction mechanisms.
  #
  # When one routine is called within another using the run method, there is
  # only one transaction used (barring any explicitly made in the code) and
  # its isolation level is sufficiently strict for all routines involved.
  #
  # It is highly recommend, though not required, to call the "uses_routine"
  # method to let the routine know which subroutines will be called within it.
  # This will let a routine set its isolation level appropriately, and will
  # enforce that only one transaction be used and that it be rolled back 
  # appropriately if any errors occur.
  #
  # uses_routine also provides a way to specify how errors relate to routine 
  # inputs. Take the following example.  A user calls Routine1 which calls 
  # Routine2.
  #
  #   User --> Routine1.call(foo: "abcd4") --> Routine2.call(bar: "abcd4")
  #
  # An error occurs in Routine2, and Routine2 notes that the error is related
  # to its "bar" input.  If that error and its metadata bubble up to the User,
  # the User won't have any idea what "bar" relates to -- the User only knows
  # about the interface to Routine1 and the "foo" parameter it gave it.
  #
  # Routine1 knows that it will call Routine2 and knows what its interface is.  
  # It can then specify how to map terminology from Routine2 into Routine1's 
  # context.  E.g., in the following class:
  #
  #   class Routine1
  #     include Lev::Routine
  #     uses_routine Routine2,
  #                  translation: { mapping: {bar: :foo} }
  #     def exec(options)
  #       run(Routine2, bar: options[:foo])
  #     end
  #   end
  #
  # Routine1 notes that any errors coming back from the call to Routine2 
  # related to :bar should be transfered into Routine1's errors object
  # as being related to :foo.  In this way, the caller of Routine1 will see
  # errors related to the arguments he understands.
  #
  # Manages running of routines inside other routines.  In the Lev context, 
  # Handlers and Algorithms are routines.  A routine and any routines nested
  # inside of it are executed within a single transaction, or depending on the
  # requirements of all the routines, no transaction at all.
  #
  # Routine class have access to a few other methods:
  #
  #  1) a "runner" accessor which points to the routine which called it. If
  #     runner is nil that means that no other routine called it (some other 
  #     code did)
  # 
  #  2) a "topmost_runner" which points to the highest routine in the calling
  #     hierarchy (that routine whose 'runner' is nil)
  #
  # A routine returns an "outcome" object, which is just a simple wrapper
  # of the results and errors objects. 
  #   
  # References:
  #   http://ducktypo.blogspot.com/2010/08/why-inheritance-sucks.html
  #
  module Routine

    class Outcome
      attr_reader :results
      attr_reader :errors

      def initialize
        @results = {}
        @errors = Errors.new
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def call(*args, &block)
        new.call(*args, &block)
      end

      # Called at a routine's class level to foretell which other routines will
      # be used when this routine executes.  Helpful for figuring out ahead of
      # time what kind of transaction isolation level should be used.
      def uses_routine(routine_class, options={})
        symbol = options[:as] || class_to_symbol(routine_class)

        raise IllegalArgument, "Routine #{routine_class} has already been registered" \
          if nested_routines[symbol]

        options[:translation] ||= {}
        input_mapper = InputMapper.new(options[:translation][:scope],
                                       options[:translation][:mapping])

        nested_routines[symbol] = {
          routine_class: routine_class,
          input_mapper: input_mapper
        }

        transaction_isolation.replace_if_more_isolated(routine_class.transaction_isolation)
      end

      def transaction_isolation
        @transaction_isolation ||= default_transaction_isolation
      end

      def default_transaction_isolation
        TransactionIsolation.mysql_default
      end

      def nested_routines
        @nested_routines ||= {}
      end

      def class_to_symbol(klass)
        klass.name.underscore.gsub('/','_').to_sym
      end
    end

    attr_reader :runner

    def call(*args, &block)
      self.outcome = Outcome.new

      in_transaction do
        catch :fatal_errors_encountered do
          exec(*args, &block)
        end
      end

      self.outcome
    end

    # Returns true iff the given instance is responsible for running itself in a
    # transaction
    def transaction_run_by?(who)
      who == topmost_runner && who.class.transaction_isolation != TransactionIsolation.no_transaction
    end

    def run_with_options(other_routine, options, *args, &block)
      options[:errors_are_fatal] = true if !options.has_key?(:errors_are_fatal)

      symbol = case other_routine
               when Symbol
                 other_routine
               when Class
                 self.class.class_to_symbol(other_routine)
               else 
                 self.class.class_to_symbol(other_routine.class)
               end

      nested_routine = self.class.nested_routines[symbol] || {}

      if nested_routine.empty? && other_routine == symbol
        raise IllegalArgument, 
              "Routine symbol #{other_routine} does not point to a registered routine"
      end      

      other_routine = nested_routine[:routine_class] || other_routine
      other_routine = other_routine.new if other_routine.is_a? Class

      input_mapper = nested_routine[:input_mapper] || InputMapper.new

      raise IllegalArgument, "Can only run another nested routine" \
        if !(other_routine.includes_module? Lev::Routine)

      other_routine.runner = self
      run_outcome = other_routine.call(*args, &block)
      transfer_errors_from(run_outcome.errors, input_mapper)
      throw :fatal_errors_encountered if errors.any? && options[:errors_are_fatal]

      run_outcome
    end

    def run(other_routine, *args, &block)
      run_with_options(other_routine, {}, *args, &block)
    end

    # Convenience accessor for errors object
    def errors
      outcome.errors
    end

    # Convenience test for presence of errors
    def errors?
      outcome.errors.any?
    end

    # Job of this method is to put errors in the source context into self's context.
    def transfer_errors_from(source, input_mapper=InputMapper.new)

      if input_mapper.is_a? Hash
        input_mapper = InputMapper.new(input_mapper[:scope], input_mapper[:mapping])
      end

      ErrorTransferer.transfer(source, self, input_mapper)
    end

  protected

    attr_accessor :outcome
    attr_writer :runner

    def results
      outcome.results
    end

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

    def in_transaction(options={}) 
      if transaction_run_by?(self)
        ActiveRecord::Base.isolation_level( self.class.transaction_isolation.symbol ) do
          ActiveRecord::Base.transaction do 
            yield 
            raise ActiveRecord::Rollback if errors?
          end
        end
      else
        yield
      end
    end

  end
end