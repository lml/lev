module Lev
  module ActiveJob
    class Base < Lev.configuration.job_class
      def self.perform_later(routine_class, *args, &block)
        queue_as routine_class.active_job_queue
        args.push(routine_class.to_s)

        # Create a new status object and push its ID on to the arguments so that
        # in `perform` it can be used to retrieve the status when the routine is
        # initialized.
        status = Lev::create_status
        args.push(status.id)

        # In theory we'd mark as queued right after the call to super, but this messes
        # up when the activejob adapter runs the job right away
        status.queued!
        super(*args, &block)

        status.id
      end

      def perform(*args, &block)
        # Pop arguments added by perform_later
        id = args.pop
        routine_class = Kernel.const_get(args.pop)

        routine_instance = routine_class.new(Lev::find_status(id))

        routine_instance.call(*args, &block)
      end
    end
  end
end
