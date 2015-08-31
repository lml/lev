if defined?(::ActiveJob)
  module Lev
    module ActiveJob
      class Base < ::ActiveJob::Base
        def self.perform_later(routine_class, *args, &block)
          queue_as routine_class.active_job_queue
          args.push(routine_class.to_s)

          # To enable tracking of this job's status, create a new BackgroundJob object
          # and push it on to the arguments so that in `perform` it can be peeled
          # off and handed to the routine instance.  The BackgroundJob UUID is returned
          # so that callers can track the status.
          job = Lev::BackgroundJob.create
          args.push(job.id)

          # In theory we'd mark as queued right after the call to super, but this messes
          # up when the activejob adapter runs the job right away
          job.queued!
          super(*args, &block)

          job.id
        end

        def perform(*args, &block)
          # Pop arguments added by perform_later
          id = args.pop
          routine_class = Kernel.const_get(args.pop)

          routine_instance = routine_class.new(Lev::BackgroundJob.find!(id))
          routine_instance.call(*args, &block)
        end
      end
    end
  end
end
