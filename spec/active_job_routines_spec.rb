require 'spec_helper'

RSpec.describe 'ActiveJob routines' do

  before { Lev::Jobba.use_jobba }

  context 'default configuration' do
    class LaterRoutine
      lev_routine active_job_enqueue_options: { queue: :something_else }

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
      Jobba.all.delete_all!

      expect{
        ExceptionalRoutine.perform_later
      }.to raise_error(TypeError)

      status = Jobba.all.run.to_a.first

      expect(status).to be_failed

      error = status.errors.first

      expect(error["code"]).to eq "exception"
      expect(error["message"]).to eq "howdy there"
      expect(error["data"]).to be_a String
    end
  end
end
