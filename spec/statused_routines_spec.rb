require 'spec_helper'

class StatusedRoutine
  lev_routine

  protected
  def exec
    status.set_progress(9, 10)
    status.save({'hi' => 'there'})
    fatal_error(code: 'blah', message: 'hi')
  end
end

RSpec.describe 'Statused Routines' do

  before { Lev::Jobba.use_jobba }

  context 'in a routine' do
    it 'queues the job object on queue' do
      id = StatusedRoutine.perform_later
      status = Jobba::Status.find(id)

      expect(status).to be_queued
    end

    context 'inline activejob mode' do
      before { ::ActiveJob::Base.queue_adapter = :inline }
      after { ::ActiveJob::Base.queue_adapter = :test }

      it 'sets job to started when called' do
        expect_any_instance_of(Jobba::Status).to receive(:started!)
        StatusedRoutine.perform_later
      end

      it 'completes the status object on completion, returning other data' do
        id = StatusedRoutine.perform_later
        status = Jobba::Status.find(id)
        expect(status).to be_failed
        expect(status.progress).to eq(0.9)
        expect(status.errors).to contain_exactly(
          a_hash_including({'code' => 'blah', 'message' => 'hi'})
        )
        expect(status.data).to eq ({'hi' => 'there'})
      end
    end
  end

end
