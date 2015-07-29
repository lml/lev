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
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear

      LaterRoutine.perform_later

      queue_name = ActiveJob::Base.queue_adapter.enqueued_jobs.first[:queue]

      expect(queue_name).to eq('something_else')
    end

    it 'stores all the UUIDs of queued jobs' do
      Lev.configuration.status_store.clear

      job_id1 = LaterRoutine.perform_later

      expect(Lev::Status.send(:job_ids)).to eq([job_id1])
    end
  end
end
