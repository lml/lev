require "action_view"
require "transaction_isolation"
require "transaction_retry"
require "active_attr"
require "hashie"

require "lev/version"
require "lev/object"
require "lev/utilities"
require "lev/exceptions"
require "lev/better_active_model_errors"
require "lev/term_mapper"
require "lev/outputs"
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
      attr_accessor :illegal_argument_error
      attr_accessor :raise_fatal_errors
      attr_accessor :active_job_class
      attr_writer   :active_job_results_proc

      def initialize
        @form_error_class = 'error'
        @security_transgression_error = Lev::SecurityTransgression
        @illegal_argument_error = Lev::IllegalArgument
        @raise_fatal_errors = false
        @active_job_class = defined?(ActiveJob) ? ActiveJob::Base : nil
        super
      end

      def active_job_results_proc
        @active_job_results_proc ||= -> (outputs, errors) {}
      end
    end

  end
end
