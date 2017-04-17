require 'spec_helper'

class StatusedRoutine
  lev_routine

  protected

  def exec(*args)
    status.set_progress(9, 10)
    status.save('hi' => 'there')
    fatal_error(code: 'blah', message: 'hi')
  end
end

RSpec.describe 'Statused Routines' do

  before { Lev::Jobba.use_jobba }

  let(:routine_class) { StatusedRoutine }
  let(:args)          { ['some arg'] }
  let(:status_id)     { routine_class.perform_later(*args) }
  let(:status)        { Jobba::Status.find(status_id) }

  context 'in a routine' do
    it 'sets the job_name on the status' do
      expect(status.job_name).to eq routine_class.name
    end

    it 'sets the provider_job_id on the status' do
      expect_any_instance_of(Lev::ActiveJob::Base).to receive(:provider_job_id).and_return(42)

      expect(status.provider_job_id).to eq 42
    end

    it 'sets the status to queued' do
      expect(status).to be_queued
    end

    context 'inline activejob mode' do
      before { ::ActiveJob::Base.queue_adapter = :inline }
      after { ::ActiveJob::Base.queue_adapter = :test }

      it 'sets job to started when called' do
        expect_any_instance_of(Jobba::Status).to receive(:started!)
        routine_class.perform_later
      end

      it 'completes the status object on completion, returning other data' do
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
