
module Lev

  class Paramifier
  end

  # Common methods for all handlers.  Handlers are classes that are responsible 
  # for taking input data from a form or other widget and doing something
  # with it.
  #
  # All handlers must:
  #   2) include this module ("include Lev::Handler")
  #   3) implement the 'exec' method which takes no arguments and does the 
  #      work the handler is charged with
  #   4) implement the 'authorized?' method which returns true iff the 
  #      caller is authorized to do what the handler is charged with
  #
  # Handlers may:
  #   1) implement the 'setup' method which runs before 'authorized?' and 'exec'.
  #      This method can do anything, and will likely include setting up some 
  #      instance objects based on the params.
  #   2) Call the class method "paramify" to declare, cast, and validate parts of
  #      the params hash. The first argument to paramify is the key in params
  #      which points to a hash of params to be paramified.  The block passed to
  #      paramify looks just like the guts of an ActiveAttr model.  Examples:
  #      
  #      when the incoming params includes :search => {:type, :terms, :num_results}
  #      the Handler class would look like:
  #
  #      class MyHandler
  #        include Lev::Handler
  #
  #        paramify :search do
  #          attribute :search_type, type: String
  #          validates :search_type, presence: true,
  #                                  inclusion: { in: %w(Name Username Any),
  #                                               message: "is not valid" }
  #
  #          attribute :search_terms, type: String
  #          validates :search_terms, presence: true
  #
  #          attribute :num_results, type: Integer
  #          validates :num_results, numericality: { only_integer: true,
  #                                            greater_than_or_equal_to: 0 }                               
  #        end
  #        
  #        def exec
  #          # By this time, if there were any errors the handler would have
  #          # already populated the errors object and returned.
  #          #
  #          # Paramify makes a 'search_params' attribute available through
  #          # which you can access the paramified params, e.g.
  #          x = search_params.num_results
  #          ...
  #        end
  #      end
  #
  # All handler instance methods have the following available to them:
  #   1) 'params' --  the params from the input
  #   2) 'caller' --  the user submitting the input
  #   3) 'errors' --  an object in which to store errors
  #   4) 'results' -- a hash in which to store results for return to calling code
  #   
  # See the documentation for Lev::RoutineNesting about other requirements and 
  # capabilities of handler classes.
  #
  # The handle methods take a hash of arguments.  
  #   caller: the calling user
  #   params: the params object
  #   request: the http request object
  # 
  # These arguments are optional or required depending on the implementation of
  # the specific handler, i.e. if a handler wants to use the 'caller' method, it 
  # must have been supplied to the handle method.  
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

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        include Lev::RoutineNesting
      end
    end

    def handle(options={})
      in_transaction do
        handle_guts(options)
      end
    end

    alias_method :call, :handle

    module ClassMethods
      def handle(options={})
        new.handle(options)
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
    attr_accessor :request
    attr_accessor :options
    attr_accessor :caller
    attr_accessor :results

    def handle_guts(options)
      self.params = options.delete(:params)
      self.request = options.delete(:request)
      self.caller = options.delete(:caller)
      self.options = options
      self.errors = Errors.new
      self.results = {}

      setup
      raise Lev.configuration.security_transgression_error unless authorized?
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

  end

end
