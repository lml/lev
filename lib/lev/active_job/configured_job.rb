module Lev
  module ActiveJob
    class ConfiguredJob
      attr_reader :routine_class

      def initialize(routine_class, options)
        @routine_class = routine_class
        @options = options
      end

      def options
        routine_class.active_job_enqueue_options.merge(@options)
      end

      def perform_later(*args, &block)
        routine_class.job_class.new.perform_later(routine_class, options, *args, &block)
      end
    end
  end
end
