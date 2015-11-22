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
      @result ||= Result.new(self.class.manifest, errors)
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
      routine = self.class.nested_routines[routine_name]
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

      def nested_routines
        @nested_routines ||= {}
      end

      private
      def setup_routine_getters(options)
        options.each do |key, value|
          instance_variable_set("@#{key}", value)

          define_singleton_method(key) do
            instance_variable_get("@#{key}")
          end
        end

        setup_manifest_getter if @manifest.nil?
      end

      def setup_manifest_getter
        @manifest = {}
        define_singleton_method('manifest') { @manifest }
      end

      def setup_nested_routine_manifest(options)
        manifest = options[:manifest] || {}
        map = manifest.select { |_, source| source != :_self }

        map.each do |attribute, source|
          nested_routines[source] ||= {
            routine_class: source.to_s.classify.constantize,
            attributes: []
          }

          nested_routines[source][:attributes] << attribute
        end
      end
    end

    private
    def job
      @job ||= Lev::NoBackgroundJob.new
    end
  end
end
