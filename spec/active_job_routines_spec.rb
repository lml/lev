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
      Lev.configuration.job_store.clear

      job_id1 = LaterRoutine.perform_later

      expect(Lev::BackgroundJob.send(:job_ids)).to eq([job_id1])
    end
  end

  it 'does not duplicate BackgroundJobs in `all`' do
    # Previous track_job_id implementation changed string objects in job_ids
    # resulting in duplicate objects in `all`
    LaterRoutine.perform_later
    expect(Lev::BackgroundJob.all.count).to eq 1
  end

  context 'exception raised' do
    before { ::ActiveJob::Base.queue_adapter = :inline }
    after { ::ActiveJob::Base.queue_adapter = :test }

    class ExceptionalRoutine
      lev_routine

      protected
      def exec
        raise TypeError, 'howdy there'
      end
    end

    it 'lets exception escape, job is failed and has error details' do
      Lev.configuration.job_store.clear

      expect{
        ExceptionalRoutine.perform_later
      }.to raise_error(TypeError)

      job = Lev::BackgroundJob.all.first

      expect(job.status).to eq Lev::BackgroundJob::STATE_FAILED

      error = job.errors.first

      expect(error["code"]).to eq "exception"
      expect(error["message"]).to eq "howdy there"
      expect(error["data"]).to be_a String
    end
  end
end
