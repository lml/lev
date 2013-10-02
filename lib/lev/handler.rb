
module Lev

  class Paramifier
    def as_hash(keys)
      keys = [keys].flatten.compact
      Hash[keys.collect { |key| [key, self.send(key)] }]
    end
  end

  # Common methods for all handlers.  Handlers are extensions of Routines 
  # and are responsible for taking input data from a form or other widget and 
  # doing something with it.  See Lev::Routine for more information.
  #
  # All handlers must:
  #   2) include this module ("include Lev::Handler")
  #   3) implement the 'handle' method which takes no arguments and does the 
  #      work the handler is charged with
  #   4) implement the 'authorized?' method which returns true iff the 
  #      caller is authorized to do what the handler is charged with
  #
  # Handlers may:
  #   1) implement the 'setup' method which runs before 'authorized?' and 'handle'.
  #      This method can do anything, and will likely include setting up some 
  #      instance objects based on the params.
  #   2) Call the class method "paramify" to declare, cast, and validate parts of
  #      the params hash. The first argument to paramify is the key in params
  #      which points to a hash of params to be paramified.  The block passed to
  #      paramify looks just like the guts of an ActiveAttr model.
  #      
  #      When the incoming params includes :search => {:type, :terms, :num_results}
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
  #        def handle
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
  #   5) 'request' -- the HTTP request
  #   6) 'options' -- a hash containing the options passed in, useful for other
  #                   nonstandard data.
  #
  # These methods are available iff these data were supplied in the call
  # to the handler (not all handlers need all of this).  However, note that
  # the Lev::HandleWith module supplies an easy way to call Handlers from 
  # controllers -- when this way is used, all of the methods above are available.
  #
  # Handler 'handle' methods don't return anything; they just set values in 
  # the errors and results objects.  The documentation for each handler
  # should explain what the results will be and any nonstandard data required
  # to be passed in in the options.
  #
  # In addition to the class- and instance-level "call" methods provided by 
  # Lev::Routine, Handlers have a class-level "handle" method (an alias of
  # the class-level "call" method).  The convention for handlers is that the
  # call methods take a hash of options/inputs.  The instance-level handle
  # method doesn't take any arguments since the arguments have been stored
  # as instance variables by the time the instance-level handle method is called.
  # 
  # Example:
  # 
  #   class MyHandler
  #     include Lev::Handler
  #   protected
  #     def authorized?
  #       # return true iff exec is allowed to be called, e.g. might
  #       # check the caller against the params
  #     def handle
  #       # do the work, add errors to errors object and results to the results hash as needed
  #     end
  #   end
  #
  module Handler

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        include Lev::Routine
      end
    end

    module ClassMethods
  
      def handle(options={})
        call(options)
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

  protected

    attr_accessor :params
    attr_accessor :request
    attr_accessor :options
    attr_accessor :caller

    # Provided for development / debugging purposes -- gives a way to pass
    # information in a raised security transgression when authorized? is false
    attr_accessor :auth_error_details

    # This is a method required by Lev::Routine.  It enforces the steps common
    # to all handlers.  
    def exec(options)
      self.params = options.delete(:params)
      self.request = options.delete(:request)
      self.caller = options.delete(:caller)
      self.options = options

      setup
      raise Lev.configuration.security_transgression_error, auth_error_details unless authorized?
      validate_paramified_params
      handle unless errors?
    end

    # Default setup implementation -- a no-op
    def setup; end

    # Default authorized? implementation.  It returns true so that every 
    # handler realization has to make a conscious decision about who is authorized
    # to call the handler. To help the common error of forgetting to override this 
    # method in a handler instance, we provide an error message when this default
    # implementation is called.
    def authorized?
      self.auth_error_details = 
        "Access to handlers is prevented by default.  You need to override the " +
        "'authorized?' in this handler to explicitly grant access."
      false
    end

    

    # Helper method to validate paramified params and to transfer any errors
    # into the handler.
    def validate_paramified_params
      self.class.paramify_methods.each do |method|
        params = send(method)
        transfer_errors_from(params, TermMapper.scope(params.group)) if !params.valid?
      end
    end

  end

end
