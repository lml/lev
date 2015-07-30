require 'spec_helper'

class StatusedRoutine
  lev_routine

  protected
  def exec
    status.set_progress(9, 10)
  end
end

RSpec.describe 'Statused Routines' do
  subject(:status) { Lev::Status.new }

  context 'in a routine' do
    it 'queues the status object on queue' do
      id = StatusedRoutine.perform_later
      status = Lev::Status.find(id)

      expect(status.status).to eq(Lev::Status::STATE_QUEUED)
    end

    context 'inline activejob mode' do
      before { ::ActiveJob::Base.queue_adapter = :inline }
      after { ::ActiveJob::Base.queue_adapter = :test }

      it 'sets status to working when called' do
        expect_any_instance_of(Lev::Status).to receive(:working!)
        StatusedRoutine.perform_later
      end

      it 'completes the status object on completion, returning other data' do
        id = StatusedRoutine.perform_later
        status = Lev::Status.find(id)
        expect(status.status).to eq(Lev::Status::STATE_COMPLETED)
        expect(status.progress).to eq(0.9)
      end
    end
  end

  describe '#save' do
    it 'saves the hash given and writes them to the status' do
      status.save(something: 'else')
      expect(status.something).to eq('else')
    end
  end

  describe '#add_error' do
    it 'adds the error object data to the status object' do
      errors = Lev::Error.new(code: 'bad', message: 'awful')
      status.add_error(errors)
      expect(status.errors).to eq([{ is_fatal: false,
                                     code: 'bad',
                                     message: 'awful' }])
    end
  end

  describe 'dynamic status setters/getters' do
    it 'is queued' do
      expect(status).to be_queued
    end

    it 'is working' do
      expect(status).not_to be_working
      status.working!
      expect(status).to be_working
    end

    it 'is completed' do
      expect(status).not_to be_completed
      status.completed!
      expect(status).to be_completed
    end

    it 'is failed' do
      expect(status).not_to be_failed
      status.failed!
      expect(status).to be_failed
    end

    it 'is killed' do
      expect(status).not_to be_killed
      status.killed!
      expect(status).to be_killed
    end

    it 'is unknown' do
      expect(status).not_to be_unknown
      status.unknown!
      expect(status).to be_unknown
    end
  end

  describe '#set_progress' do
    it 'sets the progress key on the status object' do
      status.set_progress(8, 10)
      expect(status.progress).to eq(0.8)
    end

    context 'when `out_of` is supplied' do
      it 'requires a positive `at` float or integer' do
        expect {
          status.set_progress(nil, 1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          status.set_progress(-1, 1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          status.set_progress(2, 5)
        }.not_to raise_error
      end

      it 'requires `out_of` to be greater than `at`' do
        expect {
          status.set_progress(15, 8)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          status.set_progress(5, 10)
        }.not_to raise_error
      end
    end

    context 'without out_of specified' do
      it 'requires `at` to be a float between 0.0 and 1.0' do
        expect {
          status.set_progress(1.1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          status.set_progress(-1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          status.set_progress(0.78)
        }.not_to raise_error
      end
    end

  end
end
