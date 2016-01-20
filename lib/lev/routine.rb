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
  #   lev_routine
  #
  # in its definition.
  #
  # Other than that, all a routine has to do is implement an "exec" method
  # that takes arbitrary arguments and that adds errors to an internal
  # array-like "errors" object and outputs to a "outputs" hash.
  #
  # A routine returns an "Result" object, which is just a simple wrapper
  # of the outputs and errors objects.
  #
  # A routine will automatically get both class- and instance-level "call"
  # methods that take the same arguments as the "exec" method.  The class-level
  # call method simply instantiates a new instance of the routine and calls
  # the instance-level call method (side note here is that this means that
  # routines aren't typically instantiated with state).
  #
  # A routine is automatically run within a transaction.  The isolation level
  # of the routine can be set by passing a :transaction option to the lev_routine
  # call (or to the lev_handler call, if appropriate).  The value must be one of
  #
  #   :no_transaction
  #   :read_uncommitted
  #   :read_committed
  #   :repeatable_read
  #   :serializable
  #
  # e.g.
  #
  #   class MyRoutine
  #     lev_routine transaction: :no_transaction
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
  # Once a routine has been registered with the "uses_routine" call, it can
  # be run by passing run the routine's Class or a symbol identifying the
  # routine.  This symbol can be set with the :as option.  If not set, the
  # symbol will be automatically set by converting the routine class' full
  # name to a symbol. e.g:
  #
  #   uses_routine CreateUser
  #                as: :cu
  #
  # and then you can say either:
  #
  #   run(:cu, ...)
  #
  # or
  #
  #   run(:create_user, ...)
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
  #     lev_routine
  #     uses_routine Routine2,
  #                  translations: {
  #                    inputs: { map: {bar: :foo} }
  #                  }
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
  # Translations can also be supplied for "outputs" in addition to "inputs".
  # Output translations control how a called routine's Result outputs are
  # transfered to the calling routine's outputs.  Note if multiple outputs are
  # transferred into the same named output, an array of those outputs will be
  # store.  The contents of the "inputs" and "outputs" hashes can be of the
  # following form:
  #
  # 1) Scoped.  Appends the provided scoping symbol (or symbol array) to
  #    the input symbol.
  #
  #    {scope: SCOPING_SYMBOL_OR_SYMBOL_ARRAY}
  #
  #    e.g. with {scope: :register} and a call to a routine that has an input
  #    named :first_name, an error in that called routine related to its
  #    :first_name input will be translated so that the offending input is
  #    [:register, :first_name].
  #
  # 2) Verbatim.  Uses the same term in the caller as the callee.
  #
  #    {type: :verbatim}
  #
  # 3) Mapped.  Give an explicit, custom mapping:
  #
  #    {map: {called_input1: caller_input1, called_input2: :caller_input2}}
  #
  # 4) Scoped and mapped.  Give an explicit mapping, and also scope the
  #    translated terms.  Just use scope: and map: from above in the same hash.
  #
  # Via the uses_routine call, you can also ignore specified errors that occur
  # in the called routine. e.g.:
  #
  #   uses_routine DestroyUser,
  #                ignored_errors: [:cannot_destroy_non_temp_user]
  #
  # ignores errors with the provided code.  The ignore_errors key must point
  # to an array of code symbols or procs.  If a proc is given, the proc will
  # be called with the error that the routine is trying to add.  If the proc
  # returns true, the error will be ignored.
  #
  # Any option passed to uses_routine can also be passed directly to the run
  # method.  To achieve this, pass an array as the first argument to "run".
  # The array should have the routine class or symbol as the first argument,
  # and the hash of options as the second argument.  Options passed in this
  # manner override any options provided in uses_routine (though those options
  # are still used if not replaced in the run call).
  #
  # Two methods are provided for adding errors: "fatal_error" and "nonfatal_error".
  # Both take a hash of args used to create an Error and the former stops routine
  # execution.  In its current implementation, "nonfatal_error" may still cause
  # a routine higher up in the execution hierarchy to halt running.
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
  # References:
  #   http://ducktypo.blogspot.com/2010/08/why-inheritance-sucks.html
  #
  module Routine

    class Result
      attr_reader :outputs
      attr_reader :errors

      def initialize(outputs, errors)
        @outputs = outputs
        @errors = errors
      end
    end

    attr_reader :id

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def call(*args, &block)
        new.call(*args, &block)
      end

      def [](*args, &block)
        result = call(*args, &block)
        result.errors.raise_exception_if_any!
        result.outputs.send(@express_output)
      end

      def perform_later(*args, &block)
        # Delegate to a subclass of Lev::Routine::ActiveJob::Base
        Lev::ActiveJob::Base.perform_later(self, *args, &block)
      end

      def active_job_queue
        @active_job_queue || :default
      end

      # Called at a routine's class level to foretell which other routines will
      # be used when this routine executes.  Helpful for figuring out ahead of
      # time what kind of transaction isolation level should be used.
      def uses_routine(routine_class, options={})
        symbol = options[:as] || class_to_symbol(routine_class)

        raise Lev.configuration.illegal_argument_error, "Routine #{routine_class} has already been registered" \
          if nested_routines[symbol]

        nested_routines[symbol] = {
          routine_class: routine_class,
          options: options
        }

        transaction_isolation.replace_if_more_isolated(routine_class.transaction_isolation)
      end

      def transaction_isolation
        @transaction_isolation ||= TransactionIsolation.mysql_default
      end

      def express_output
        @express_output
      end

      def delegates_to
        @delegates_to
      end

      def nested_routines
        @nested_routines ||= {}
      end

      def raise_fatal_errors?
        @raise_fatal_errors ||
          (Lev.configuration.raise_fatal_errors && @raise_fatal_errors.nil?)
      end

      def class_to_symbol(klass)
        klass.name.underscore.gsub('/','_').to_sym
      end
    end

    attr_reader :runner

    def call(*args, &block)
      @after_transaction_blocks = []

      job.working!

      begin
        in_transaction do
          reset_result! if transaction_run_by?(self)

          catch :fatal_errors_encountered do
            if self.class.delegates_to
              run(self.class.delegates_to, *args, &block)
            else
              exec(*args, &block)
            end
          end
        end

        @after_transaction_blocks.each do |block|
          block.call
        end
      rescue Exception => e
        # Let exceptions escape but make sure to note the error in the job
        # if not already done
        if !e.is_a?(Lev::FatalError)
          error = Error.new(code: :exception,
                            message: e.message,
                            data: e.backtrace.first)
          job.add_error(error, is_fatal: true)
          job.failed!
        end

        raise e
      end

      job.succeeded! if !errors?

      result
    end

    # Returns true iff the given instance is responsible for running itself in a
    # transaction
    def transaction_run_by?(who)
      who == topmost_runner && who.class.transaction_isolation != TransactionIsolation.no_transaction
    end

    def run(other_routine, *args, &block)
      options = {}

      if other_routine.is_a? Array
        if other_routine.size != 2
          raise Lev.configuration.illegal_argument_error, "when first arg to run is an array, it must have two arguments"
        end

        other_routine = other_routine[0]
        options = other_routine[1]
      end

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
        raise Lev.configuration.illegal_argument_error,
              "Routine symbol #{other_routine} does not point to a registered routine"
      end

      #
      # Get an instance of the routine and make sure it is a routine
      #

      other_routine = nested_routine[:routine_class] || other_routine
      other_routine = other_routine.new if other_routine.is_a? Class

      if !(other_routine.includes_module? Lev::Routine)
        raise Lev.configuration.illegal_argument_error, "Can only run another nested routine"
      end

      #
      # Merge passed-in options with those set in uses_routine, the former taking
      # priority.
      #

      nested_routine_options = nested_routine[:options] || {}
      options = Lev::Utilities.deep_merge(nested_routine_options, options)

      #
      # Setup the input/output mappers
      #

      options[:translations] ||= {}

      input_mapper  = new_term_mapper(options[:translations][:inputs]) ||
                      new_term_mapper({ scope: symbol })

      output_mapper = new_term_mapper(options[:translations][:outputs]) ||
                      new_term_mapper({ scope: symbol })

      #
      # Set up the ignored errors in the routine instance
      #

      (options[:ignored_errors] || []).each do |ignored_error|
        other_routine.errors.ignore(ignored_error)
      end

      #
      # Attach the subroutine to self, call it, transfer errors and results
      #

      other_routine.runner = self
      run_result = other_routine.call(*args, &block)

      options[:errors_are_fatal] = true if !options.has_key?(:errors_are_fatal)
      transfer_errors_from(run_result.errors, input_mapper, options[:errors_are_fatal])

      run_result.outputs.transfer_to(outputs) do |name|
        output_mapper.map(name)
      end

      run_result
    end

    # Convenience accessor for errors object
    def errors
      result.errors
    end

    # Convenience test for presence of errors
    def errors?
      result.errors.any?
    end

    def fatal_error(args={})
      errors.add(true, args)
    end

    def nonfatal_error(args={})
      errors.add(false, args)
    end

    # Utility method to transfer errors from a source to this routine.  The
    # provided input_mapper maps the language of the errors in the source to
    # the language of this routine.  If fail_if_errors is true, this routine
    # will throw an error condition that causes execution of this routine to stop
    # *after* having transfered all of the errors.
    def transfer_errors_from(source, input_mapper, fail_if_errors=false)
      if input_mapper.is_a? Hash
        input_mapper = new_term_mapper(input_mapper)
      end

      ErrorTransferer.transfer(source, self, input_mapper, fail_if_errors)
    end

    def add_after_transaction_block(block)
      raise IllegalOperation if topmost_runner != self
      @after_transaction_blocks.push(block)
    end

    # Note that the parent may neglect to call super, leading to this method never being called.
    # Do not perform any initialization here that cannot be safely skipped
    def initialize(job = nil)
      # If someone cares about the job, they'll pass it in; otherwise all
      # job updates go into the bit bucket.
      @job = job
    end

  protected

    attr_writer :runner

    def job
       @job ||= Lev::NoBackgroundJob.new
    end

    def result
      @result ||= Result.new(Outputs.new,
                             Errors.new(job, topmost_runner.class.raise_fatal_errors?))
    end

    def reset_result!
      @result = nil
    end

    def outputs
      result.outputs
    end

    def topmost_runner
      runner.nil? ? self : runner.topmost_runner
    end

    def after_transaction(&block)
      topmost_runner.add_after_transaction_block(block)
    end

    def runner=(runner)
      @runner = runner

      if topmost_runner.class.transaction_isolation.weaker_than(self.class.transaction_isolation)
        raise IsolationMismatch,
              "The routine being run has a stronger isolation requirement than " +
              "the isolation being used by the routine(s) running it; call the " +
              "'uses' method in the running routine's initializer"
      end
    end

    def in_transaction(options={})
      if transaction_run_by?(self)
        isolation_symbol = self.class.transaction_isolation.symbol
        if ActiveRecord::VERSION::MAJOR >= 4
          begin
            ActiveRecord::Base.transaction(isolation: isolation_symbol) do
              yield
              raise ActiveRecord::Rollback if errors?
            end
          rescue ActiveRecord::TransactionIsolationError
            # Silently ignore isolation errors
            ActiveRecord::Base.transaction do
              yield
              raise ActiveRecord::Rollback if errors?
            end
          end
        else
          ActiveRecord::Base.isolation_level(isolation_symbol) do
            ActiveRecord::Base.transaction do
              yield
              raise ActiveRecord::Rollback if errors?
            end
          end
        end
      else
        yield
      end
    end

    def new_term_mapper(options)
      return nil if options.nil?

      if options[:type]
        case options[:type]
        when :verbatim
          return TermMapper.verbatim
        else
          raise Lev.configuration.illegal_argument_error, "unknown :type value: #{options[:type]}"
        end
      end

      if options[:scope] || options[:map]
        return TermMapper.scope_and_map(options[:scope], options[:map])
      end

      nil
    end

  end
end
