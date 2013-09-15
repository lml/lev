
module Lev

  class Paramifier
  end

  # Common methods for all input handlers.  Input handlers are classes that are
  # responsible for taking input data from a form or other widget and doing something
  # with it.
  #
  # All input handlers must:
  #   2) include this module ("include Lev::Handler")
  #   3) implement the 'exec' method
  #   4) implement the 'authorized?' method
  #
  # Input handlers may:
  #   1) implement the 'setup' method which runs before
  #      'authorized?' and 'exec'.  This method can do anything, and will likely
  #      include setting up some instance objects based on the params.
  #   2) implement the 'default_transaction_isolation' method to say whether or not
  #      the handler's code should be run in a transaction, and if so which
  #      isolation level to use.
  #
  # All handler instance methods have the following available to them:
  #   1) 'params' --  the params from the input
  #   2) 'caller' --  the user submitting the input
  #   3) 'errors' --  an object in which to store errors
  #   4) 'results' -- a hash in which to store results for return to calling code
  #   
  # The handle methods take the caller and the params objects, which should be 
  # self-explanatory.  They also take an optional options hash, which can contain
  # the following key/value pairs:
  #
  #   :transaction_isolation -- the transaction isolation to use (overriding the 
  #     handler's default).  One of:
  #       Lev::TransactionIsolation.no_transaction -- do not run this handler's code inside a transaction
  #       Lev::TransactionIsolation.serializable
  #       Lev::TransactionIsolation.repeatable_read
  #       Lev::TransactionIsolation.read_committed
  #       Lev::TransactionIsolation.read_uncommitted
  #
  # Example:
  # 
  #   class MyHandler
  #     include Lev::Handler
  #   protected
  #     def authorized?
  #       # return true iff exec is allowed to be called, e.g. might
  #       # check the caller against the params
  #     def exec
  #       # do the work, add errors to errors object and results to the results hash as needed
  #     end
  #   end
  #
  module Handler

    include Lev::TransactionIsolatable

    def self.included(base)
      base.extend(ClassMethods)
    end

    def handle(caller, params, options={})
      init_transaction_isolation(options[:transaction_isolation])

      run_in_transaction disable_transaction_if: runner.present? do
        handle_guts(caller, params)
      end
    end

    module ClassMethods
      def handle(caller, params, options={})
        new.handle(caller, params, options)
      end

      def paramify(group, options={}, &block)
        method_name = "#{group.to_s}_params"
        variable_sym = "@#{method_name}".to_sym

        # Generate the dynamic ActiveAttr class given
        # the paramify block; I think the caching of the class
        # in paramify_classes is only necessary to maintain
        # the name of the class set in the const_set statement

        if paramify_classes[group].nil?
          paramify_classes[group] = Class.new(Lev::Paramifier) do
            include ActiveAttr::Model
            cattr_accessor :group
          end
          paramify_classes[group].class_eval(&block)
          paramify_classes[group].group = group

          # Attach a name to this dynamic class
          const_set("#{group.to_s.capitalize}Paramifier", 
                    paramify_classes[group])
        end

        # Define the "#{group}_params" method to get the paramifier 
        # instance wrapping the params
        define_method method_name.to_sym do
          if !instance_variable_get(variable_sym)
            instance_variable_set(variable_sym, 
                                  self.class.paramify_classes[group].new(params[group]))
          end
          instance_variable_get(variable_sym)
        end

        # Keep track of the accessor for the params so we can check
        # errors in it later
        paramify_methods.push(method_name.to_sym)
      end

      def paramify_methods
        @paramify_methods ||= []
      end

      def paramify_classes
        @paramify_classes ||= {}
      end
    end

    def transfer_errors_from(source, param_group)
      ErrorTransferer.transfer(source, self, param_group)
    end

    attr_accessor :errors

  protected

    attr_accessor :params
    attr_accessor :caller
    attr_accessor :results

    def handle_guts(caller, params)
      self.params = params
      self.caller = caller
      self.errors = Errors.new
      self.results = {}

      setup
      raise SecurityTransgression unless authorized?
      validate_paramified_params
      exec unless errors?

      [self.results, self.errors]
    end

    def setup; end

    def authorized?
      false # default for safety, forces implementation in the handler
    end

    def validate_paramified_params
      self.class.paramify_methods.each do |method|
        params = send(method)
        transfer_errors_from(params, params.group) if !params.valid?
      end
    end

    def errors?
      errors.any?
    end

    # Remains to be seen if we'll have handlers running other handlers, but
    # I guess it could happen.
    attr_accessor :runner

    # Should be able to combine run_handler and run_algorithm into one
    # common method at some point

    def run_handler(other_handler, caller, params, options={})
      other_handler = other_handler.new if other_handler.is_a? Class

      raise IllegalArgument, "Provided argument is not a handler" \
        if !(other_handler.eigenclass.included_modules.include? Lev::Handler)

      other_handler.runner = self
      other_handler.handle(caller, params, options)
    end

    def run_algorithm(algorithm, *args, &block)
      algorithm = algorithm.new if algorithm.is_a? Class

      raise IllegalArgument, "Provided argument is not an 'Algorithm'" \
        if !(algorithm.eigenclass.included_modules.include? Lev::Algorithm)

      algorithm.runner = self
      algorithm.call(*args, &block)
    end

  end

end
