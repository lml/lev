require 'spec_helper'

class StatusedRoutine
  lev_routine

  protected
  def exec
    job.set_progress(9, 10)
  end
end

RSpec.describe 'Statused Routines' do
  subject(:job) { Lev::BackgroundJob.new }

  context 'in a routine' do
    it 'queues the job object on queue' do
      id = StatusedRoutine.perform_later
      job = Lev::BackgroundJob.find!(id)

      expect(job.status).to eq(Lev::BackgroundJob::STATE_QUEUED)
    end

    context 'inline activejob mode' do
      before { ::ActiveJob::Base.queue_adapter = :inline }
      after { ::ActiveJob::Base.queue_adapter = :test }

      it 'sets job to working when called' do
        expect_any_instance_of(Lev::BackgroundJob).to receive(:working!)
        StatusedRoutine.perform_later
      end

      it 'completes the job object on completion, returning other data' do
        id = StatusedRoutine.perform_later
        job = Lev::BackgroundJob.find!(id)
        expect(job.status).to eq(Lev::BackgroundJob::STATE_SUCCEEDED)
        expect(job.progress).to eq(1.0)
      end
    end
  end

  describe '#save' do
    it 'saves the hash given and writes them to the job' do
      job.save(something: 'else')
      expect(job.something).to eq('else')
    end
  end

  describe '#add_error' do
    it 'adds the error object data to the job object' do
      errors = Lev::Error.new(code: 'bad', message: 'awful')
      job.add_error(errors)
      expect(job.errors).to eq([{ is_fatal: false,
                                     code: 'bad',
                                     message: 'awful',
                                     data: nil }])
    end
  end

  describe '#save' do
    it 'prevents the use of reserved keys' do
      expect {
        job.save(progress: 'blocked')
      }.to raise_error(Lev::IllegalArgument)

      expect {
        job.save(id: 'blocked')
      }.to raise_error(Lev::IllegalArgument)

      expect {
        job.save(status: 'blocked')
      }.to raise_error(Lev::IllegalArgument)

      expect {
        job.save(errors: 'blocked')
      }.to raise_error(Lev::IllegalArgument)
    end

    it 'saves the hash given and writes them to the job' do
      job.save(something: 'else')
      expect(job).to respond_to(:something)
      expect(job.something).to eq('else')
    end
  end

  describe 'dynamic job setters/getters' do
    it 'is queued' do
      expect(job).not_to be_queued
      job.queued!
      expect(job).to be_queued
    end

    it 'is working' do
      expect(job).not_to be_working
      job.working!
      expect(job).to be_working
    end

    it 'is succeeded' do
      expect(job).not_to be_succeeded
      job.succeeded!
      expect(job).to be_succeeded
    end

    it 'is failed' do
      expect(job).not_to be_failed
      job.failed!
      expect(job).to be_failed
    end

    it 'is killed' do
      expect(job).not_to be_killed
      job.killed!
      expect(job).to be_killed
    end

    it 'is unknown' do
      expect(job).to be_unknown
    end
  end

  describe '#set_progress' do
    it 'sets the progress key on the job object' do
      job.set_progress(8, 10)
      expect(job.progress).to eq(0.8)
    end

    context 'when `out_of` is supplied' do
      it 'requires a positive `at` float or integer' do
        expect {
          job.set_progress(nil, 1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          job.set_progress(-1, 1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          job.set_progress(2, 5)
        }.not_to raise_error
      end

      it 'requires `out_of` to be greater than `at`' do
        expect {
          job.set_progress(15, 8)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          job.set_progress(5, 10)
        }.not_to raise_error
      end
    end

    context 'without out_of specified' do
      it 'requires `at` to be a float between 0.0 and 1.0' do
        expect {
          job.set_progress(1.1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          job.set_progress(-1)
        }.to raise_error(Lev::IllegalArgument)

        expect {
          job.set_progress(0.78)
        }.not_to raise_error
      end
    end

  end
end
