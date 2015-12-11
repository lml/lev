require 'lev/background_jobs'
require 'lev/outputs'
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
    alias :set_result :set

    def add_result(attrs = {})
      attrs.each do |attr, adding_value|
        sub_value = result.send(attr)
        sub_value += adding_value
        set_result(attr => sub_value)
      end
    end

    def push_result(attrs = {})
      attrs.each do |attr, pushing_value|
        sub_value = result.send(attr)
        sub_value << pushing_value
        set_result(attr => sub_value)
      end
    end

    def result
      @result ||= Result.new(self.class.outputs, errors)
    end

    def errors
      @errors ||= Errors.new(self.class.raise_fatal_errors?)
    end

    def call(*args, &block)
      job.working!

      begin
        ActiveRecord::Base.transaction {
          catch :fatal_errors_encountered do
            exec(*args, &block)
          end
        }
        job.succeeded! unless errors.any?
      rescue Exception => e
        job.failed!(e)
        raise e
      ensure
        result
      end

      result
    end

    def run(routine_name, *args, &block)
      subroutine = self.class.subroutines.routine_class(routine_name)
      sub_result = subroutine.call(*args, &block)
      subroutine.promote_mapped_attributes(self, sub_result)
      sub_result
    end

    def transfer_errors_from(model, *args)
      set(errors: model.errors)
    end

    def fatal_error(args = {})
      errors.add(args.merge(fail: true))
    end

    def nonfatal_error(args = {})
      errors.add(args.merge(fail: false))
    end

    module ClassMethods
      def call(*args, &block)
        new.call(*args, &block)
      end
      alias [] call

      def outputs
        @outputs ||= Outputs.new(self, {})
      end

      def promote_mapped_attributes(routine, sub_result)
        routine.class.subroutines.attributes(self).each do |attr|
          routine.set(attr => sub_result.send(attr))
        end
        routine.add_result(errors: (sub_result && sub_result.errors) || [])
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
