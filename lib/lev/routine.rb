require 'lev/background_jobs'
require 'lev/subroutines'
require 'lev/result'
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

    def set(attrs = {})
      result.set(attrs)
    end

    def result
      @result ||= Result.new(self.class.outputs, errors)
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

      result
    end

    def run(routine_name, *args)
      subroutine = self.class.subroutines.routine_class(routine_name)
      sub_result = subroutine.call(*args)

      subroutine_attrs = self.class.subroutines.attributes(routine_name)

      subroutine_attrs.each do |attr|
        set(attr => sub_result.send(attr))
      end
    end

    def transfer_errors_from(model)
      set(errors: model.errors)
    end

    def fatal_error(args = {})
      errors.add(args.merge(fail: true))
    end

    def nonfatal_error(args = {})
      errors.add(args.merge(fail: false))
    end

    module ClassMethods
      def call(*args)
        new.call(*args)
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

      def explicit_outputs
        outputs.select { |k, _| k != :_verbatim }.keys
      end

      def verbatim_outputs
        [outputs[:_verbatim]].flatten.compact
      end

      def subroutines
        @subroutines ||= Subroutines.new
      end

      def setup_readable_attrs(options)
        options.each do |key, value|
          instance_variable_set("@#{key}", value)

          define_singleton_method(key) do
            instance_variable_get("@#{key}")
          end
        end
      end
    end

    private
    def job
      @job ||= Lev::NoBackgroundJob.new
    end
  end
end
