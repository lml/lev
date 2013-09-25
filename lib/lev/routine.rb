module Lev
  #   http://ducktypo.blogspot.com/2010/08/why-inheritance-sucks.html
  #   http://stackoverflow.com/a/1328093/1664216
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

    def call(*args, &block)
      # self.results = {}
      # self.errors = Errors.new

      self.outcome = Outcome.new

      in_transaction do
        catch :fatal_errors_encountered do
          exec(*args, &block)
        end
        # rollback_transaction if errors? # unless runner?
      end

      # [self.results, self.errors]
      self.outcome
    end

    def in_transaction(options={}) 
      if transaction_run_by?(self)
        ActiveRecord::Base.isolation_level( self.class.transaction_isolation.symbol ) do
          ActiveRecord::Base.transaction { 
            yield 
            raise ActiveRecord::Rollback if errors?
          }
        end
      else
        yield
      end
    end

    def rollback_transaction
      raise ActiveRecord::Rollback if transaction_run_by?(topmost_runner)
    end

    # Returns true iff the given instance is responsible for running itself in a
    # transaction
    def transaction_run_by?(who)
      who == topmost_runner && who.class.transaction_isolation != TransactionIsolation.no_transaction
    end

    def run_with_options(other_routine, options, *args, &block)
    debugger
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
      # run_results, run_errors = other_routine.call(*args, &block)
      run_outcome = other_routine.call(*args, &block)
     debugger 
      transfer_errors_from(run_outcome.errors, input_mapper)
      throw :fatal_errors_encountered if errors.any? && options[:errors_are_fatal]

      run_outcome
    end

    def run(other_routine, *args, &block)
      run_with_options(other_routine, {}, *args, &block)
    end

    attr_reader :runner

    # # Adds error code to the list of ignored errors (making raise_error not do
    # # anything for that code), and returns self so calls can be chained
    # def ignore_error(code)
    #   ignored_errors.push(code)
    #   self
    # end

    # attr_accessor :errors

    def errors
      outcome.errors
    end

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
    
    # attr_accessor :results


    def results
      outcome.results
    end

    def fail_if_errors!
      throw :fail_if_errors if errors.any?
    end

    # def ignored_errors
    #   @ignored_errors ||= []
    # end

    # # Raises an exception where the message is an array of symbols that target
    # # the raised error code, e.g. if ModuleA::Algorithm4 raises a :foo error code
    # # the exception's message will be [:module_a, :algorithm4, :foo].  This code
    # # can then be used in locale translations (TBD).
    # def raise_error(code, options={})
    #   return if ignored_errors.include?(code)
    #   full_code = self.class.name.underscore.split("/").collect{|part| part.to_sym}.push(code)
    #   raise (options[:exception] || Lev::AlgorithmError), full_code
    # end

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