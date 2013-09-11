
module Lev

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
  #
  # All handler instance methods have the following available to them:
  #   1) 'params' --  the params from the input
  #   2) 'caller' --  the user submitting the input
  #   3) 'errors' --  an object in which to store errors
  #   4) 'results' -- a hash in which to store results for return to calling code
  #   
  # this module, e.g.:
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
    end

    def handle(caller, params)
      containing_handler.present? ?
        handle_guts(caller, params) :
        ActiveRecord::Base.transaction { handle_guts(caller, params) }
    end

    module ClassMethods
      def handle(caller, params)
        new.handle(caller, params)
      end
    end

    class Error
      # need a type or source that can be :activerecord
      # when activerecord, data should contain specific fields that
      # can be used by generate_message in BetterErrors
      attr_accessor :scope
      attr_accessor :code
      attr_accessor :data
      attr_accessor :ui_label

      def initialize(args={})
        raise IllegalArgument if args[:code].blank?
        self.scope = args[:scope]
        self.code = args[:code]
        self.data = args[:data]
        self.ui_label = args[:ui_label]
      end
    end

    class Errors < Array
      def add(args)
        push(Error.new(args))
      end

      def [](key)
        self[key]
      end

      def includes?(scope, ui_label)
        self.any?{|e| e.scope == scope && e.ui_label == ui_label}
      end
    end

    def transfer_model_errors(model_object)
      model_object.errors.each_type do |attribute, type|
        errors.add(scope: :register, code: type, data: model_object, ui_label: attribute)
      end
    end

  protected

    attr_accessor :params
    attr_accessor :caller
    attr_accessor :errors
    attr_accessor :results

    def handle_guts(caller, params)
      self.caller = caller
      self.params = params
      self.errors = Errors.new
      self.results = {}

      setup
      raise SecurityTransgression unless authorized?
      exec

      [self.results, self.errors]
    end

    def setup; end

    def authorized?
      false # default for safety, forces implementation in the handler
    end

    # don't know if we really need this nesting capability like in algorithm
    attr_accessor :containing_handler

    def handle_nested(other_handler, caller, params)
      other_handler = other_handler.new if other_handler.is_a? Class

      raise IllegalArgument, "A handler can only nestedly handle another handler" \
        if !(other_handler.eigenclass.included_modules.include? InputHandler)

      other_handler.containing_handler = self
      other_handler.handle(caller, params)
    end

  end

  # A utility method for calling handlers from controllers.  To use,
  # include this in your relevant controllers (or in your ApplicationController),
  # e.g.:
  #
  #   class ApplicationController
  #     include Lev::HandleWith
  #     ...
  #   end
  #
  # Then, call it from your various controller actions, e.g.:
  #
  #   handle_with(MyFormHandler,
  #               params: params,
  #               success: lambda { redirect_to 'show', notice: 'Success!'},
  #               failure: lambda { render 'new', alert: 'Error' })
  #
  # handle_with takes care of calling the handler and populates
  # @errors and @results objects with the return values from the handler
  #
  # The 'success' and 'failure' lambdas are called if there aren't or are errors,
  # respectively.  Alternatively, if you supply a 'complete' lambda, that lambda
  # will be called regardless of whether there are any errors.
  #
  module HandleWith
    def handle_with(handler, options)
      options[:success] ||= lambda {}
      options[:failure] ||= lambda {}

      @results, @errors = handler.handle(current_user, options[:params])

      if options[:complete].nil?
        @errors.empty? ?
          options[:success].call :
          options[:failure].call    
      else
        options[:complete].call
      end
    end
  end

end
