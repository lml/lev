require "action_view"
require "transaction_isolation"
require "transaction_retry"
require "active_attr"

require "lev/version"
require "lev/utilities"
require "lev/exceptions"
require "lev/better_active_model_errors"
require "lev/term_mapper"
require "lev/routine"
require "lev/handler"
require "lev/handle_with"
require "lev/handler_helper"
require "lev/error"
require "lev/errors"
require "lev/error_transferer"
require "lev/error_translator"

require "lev/form_builder"
require "lev/delegate_to_routine"
require "lev/transaction_isolation"


module Lev
  class << self
    
    ###########################################################################
    #
    # Configuration machinery.
    #
    # To configure Lev, put the following code in your applications 
    # initialization logic (eg. in the config/initializers in a Rails app)
    #
    #   Lev.configure do |config|
    #     config.form_error_class = 'fancy_error'
    #     ...
    #   end
    #
    
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end

    class Configuration
      # This HTML class is added to form fields that caused errors
      attr_accessor :form_error_class
      attr_accessor :security_transgression_error
      
      def initialize      
        @form_error_class = 'error'
        @security_transgression_error = Lev::SecurityTransgression
        super
      end
    end
        
  end
end
