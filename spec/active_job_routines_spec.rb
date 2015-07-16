require 'spec_helper'

RSpec.describe 'ActiveJob routines' do
  context 'default configuration' do
    class LaterRoutine
      lev_routine active_job_queue: :something_else

      protected
      def exec; end
    end

    it 'can perform routines later' do
      expect {
        LaterRoutine.perform_later
      }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
    end

    it 'can have the default queue overridden' do
      LaterRoutine.perform_later
      queue_name = ActiveJob::Base.queue_adapter.enqueued_jobs.first[:queue]
      expect(queue_name).to eq('something_else')
    end
  end
end
