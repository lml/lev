require 'lev/background_jobs'
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
      routine = self.class.find_subroutine(routine_name)
      result = routine[:routine_class].call(*args)

      routine[:attributes].each do |attr|
        set(attr => result.send(attr))
      end
    end

    def fatal_error(args = {})
      errors.add(args.merge(fail: true))
    end

    module ClassMethods
      def call(*args); new.call(*args); end

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
        @subroutines ||= {}
      end

      def find_subroutine(name)
        name = Lev::Utils::Symbolify.exec(name)
        subroutines.select { |_, opts| opts[:name_alias] == name }.values.first
      end
    end

    private
    def job
      @job ||= Lev::NoBackgroundJob.new
    end
  end
end
