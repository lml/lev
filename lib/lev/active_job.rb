module Lev
  module ActiveJob
    class Base < Lev.configuration.job_class
      attr_accessor(:provider_job_id) unless respond_to?(:provider_job_id)

      def self.perform_later(routine_class, *args, &block)
        queue_as routine_class.active_job_queue

        # Create a new status object
        status = Lev::create_status

        # Push the routine class name on to the arguments
        # so that we can run the correct routine in `perform`
        args.push(routine_class.to_s)

        # Push the status's ID on to the arguments so that in `perform`
        # it can be used to retrieve the status when the routine is initialized
        args.push(status.id)

        # Set the job_name
        status.set_job_name(routine_class.name)

        # In theory we'd mark as queued right after the call to super, but this messes
        # up when the activejob adapter runs the job right away (inline mode)
        status.queued!

        # Queue up the job and set the provider_job_id
        # For delayed_job, requires either Rails 5 or
        # http://stackoverflow.com/questions/29855768/rails-4-2-get-delayed-job-id-from-active-job
        provider_job_id = super(*args, &block).provider_job_id
        status.set_provider_job_id(provider_job_id) \
          if provider_job_id.present? && status.respond_to?(:set_provider_job_id)

        # Return the id of the status object
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
