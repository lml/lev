require "lev/version"
require "lev/better_active_model_errors"
require "lev/handler"
require "lev/handle_with"
require "lev/handler/error"
require "lev/handler/errors"
require "lev/handler/error_transferer"
require "lev/form_builder"

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
      
      def initialize      
        @form_error_class = 'error'
        super
      end
    end
        
  end
end
