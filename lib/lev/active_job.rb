if defined?(::ActiveJob)
  module Lev
    module ActiveJob
      class Base < ::ActiveJob::Base
        def self.perform_later(routine_class, *args, &block)
          queue_as routine_class.active_job_queue
          args.push(routine_class.to_s)

          # To enable tracking of this job's status, create a new Status object
          # and push it on to the arguments so that in `perform` it can be peeled
          # off and handed to the routine instance.  The Status UUID is returned
          # so that callers can track the status.
          status = Lev::Status.new
          status.queued!
          args.push(status.uuid)

          super(*args, &block)

          status.uuid
        end

        def perform(*args, &block)
          # Pop arguments added by perform_later
          uuid = args.pop
          routine_class = Kernel.const_get(args.pop)

          routine_instance = routine_class.new(Lev::Status.new(uuid))
          routine_instance.call(*args, &block)
        end
      end
    end
  end
end
