require 'lev/background_jobs'
require 'lev/errors'

module Lev
  module Routine
    attr_accessor :errors

    def self.included(base)
      base.extend ClassMethods
    end

    def initialize(job = nil)
      @job = job
    end

    def errors
      @errors ||= Errors.new(self.class.raise_fatal_errors?)
    end

    def call(*args)
      job.working!

      begin
        ActiveRecord::Base.transaction { exec(*args) }
      rescue Exception => e
        job.failed!(e)
        raise e
      end

      job.succeeded! unless errors.any?
    end

    def run(routine_name, *args)
      self.class.nested_routines[routine_name].call(*args)
    end

    def fatal_error(args = {})
      errors.add(args.merge(fail: true))
    end

    module ClassMethods
      def call(*args); new.call(*args); end

      def uses_routine(routine, options = {})
        key = routine.name.underscore.gsub('/','_').to_sym
        nested_routines[key] = {
          routine_class: routine,
          options: options
        }
      end

      if defined?(::ActiveJob)
        def perform_later(*args, &block)
          Lev::CoreExt::ActiveJob::Base.perform_later(self, *args, &block)
        end

        def active_job_queue
          @active_job_queue || :default
        end
      end

      def raise_fatal_errors?
        @raise_fatal_errors || (Lev.configuration.raise_fatal_errors &&
                                  @raise_fatal_errors.nil?)
      end

      private
      def nested_routines
        @nested_routines ||= {}
      end
    end

    private
    def job
      @job ||= Lev::NoBackgroundJob.new
    end
  end
end
