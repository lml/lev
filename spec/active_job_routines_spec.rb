require 'spec_helper'

RSpec.describe 'ActiveJob routines' do
  context 'default configuration' do
    before do
      Lev.configure { |c| c.active_job_class = ActiveJob::Base } # default
    end

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

  context 'specialized configuration' do
    before { Lev.configure { |c| c.active_job_class = SomeOtherJobBase } }
    after { Lev.configure { |c| c.active_job_class = ActiveJob::Base } }

    class SomeOtherJobBase
      def self.queue_as(*); end
      def self.perform_later; end
    end

    class NewLaterRoutine
      lev_routine
      protected
      def exec; end
    end

    it 'allows configuration of the class' do
      allow(SomeOtherJobBase).to receive(:perform_later)

      expect(Lev.configuration.active_job_class).to eq(SomeOtherJobBase)
      NewLaterRoutine.perform_later
      expect(SomeOtherJobBase).to have_received(:perform_later)
    end
  end
end
