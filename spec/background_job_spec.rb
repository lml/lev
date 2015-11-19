require 'spec_helper'

describe Lev::BackgroundJob do
  subject(:job) { described_class.all.last }

  before do
    lev_routine_factory('DelayedRoutine', active_job_queue: :my_queue)
    Lev.configuration.job_store.clear
    allow(SecureRandom).to receive(:uuid) { '123abc' }
    DelayedRoutine.perform_later
  end

  it 'adds routines as jobs in the queue' do
    expect {
      DelayedRoutine.perform_later
    }.to change { ActiveJob::Base.queue_adapter.enqueued_jobs.count }.by(1)
  end

  it 'can have the default queue overridden' do
    Lev.configuration.job_store.clear
    DelayedRoutine.perform_later
    queue_name = ActiveJob::Base.queue_adapter.enqueued_jobs.first[:queue]
    expect(queue_name).to eq('my_queue')
  end

  it 'stores all the UUIDs of queued jobs' do
    Lev.configuration.job_store.clear
    job_id1 = DelayedRoutine.perform_later
    expect(Lev::BackgroundJob.send(:job_ids)).to eq([job_id1])
  end

  it 'behaves as a nice ruby object' do
    expect(job.id).to eq('123abc')
    expect(job.status).to eq(described_class::STATE_QUEUED)
    expect(job.progress).to eq(0.0)
  end

  it 'is unknown when not found' do
    foo = described_class.find!('noooooo')
    expect(foo.status).to eq(described_class::STATE_UNKNOWN)
  end

  it 'uses as_json' do
    expect(job.as_json).to eq({ 'id' => '123abc',
                                'status' => described_class::STATE_QUEUED,
                                'progress' => 0.0,
                                'errors' => [] })
  end

  context 'scopes' do
    describe '.incomplete' do
      it { should be_queued }

      it 'is the natural state of a job' do
        expect(described_class.incomplete.collect(&:id)).to include(job.id)
      end
    end

    describe '.queued' do
      before { job.queued! }

      it { should be_queued }

      it 'is still incmplete' do
        expect(described_class.incomplete.collect(&:id)).to include(job.id)
      end

      it 'includes the queued jobs' do
        expect(described_class.queued.collect(&:id)).to include(job.id)
      end
    end

    describe '.working' do
      before { job.working! }

      it { should be_working }

      it 'is still incmplete' do
        expect(described_class.incomplete.collect(&:id)).to include(job.id)
      end

      it 'includes the working job' do
        expect(described_class.working.collect(&:id)).to include(job.id)
      end
    end

    describe '.failed' do
      before { job.failed! }

      it { should be_failed }

      it 'is no longer incmplete' do
        expect(described_class.incomplete.collect(&:id)).not_to include(job.id)
      end

      it ' includes the failed job' do
        expect(described_class.failed.collect(&:id)).to include(job.id)
      end
    end

    describe '.killed' do
      before { job.killed! }

      it { should be_killed }

      it 'is still incmplete' do
        expect(described_class.incomplete.collect(&:id)).to include(job.id)
      end

      it 'includes the killed job' do
        expect(described_class.killed.collect(&:id)).to include(job.id)
      end
    end

    describe '.unknown' do
      before { job.unknown! }

      it { should be_unknown }

      it 'is still incmplete' do
        expect(described_class.incomplete.collect(&:id)).to include(job.id)
      end

      it 'includes unknown jobs' do
        expect(described_class.unknown.collect(&:id)).to include(job.id)
      end
    end

    describe '.succeeded' do
      before { job.succeeded! }

      it { should be_succeeded }

      it 'is no longer incmplete' do
        expect(described_class.incomplete.collect(&:id)).not_to include(job.id)
      end

      it 'includes the succeeded jobs' do
        expect(described_class.succeeded.collect(&:id)).to include(job.id)
      end
    end
  end

  it 'has the unqueued scope' do
    expect(described_class.unqueued.collect(&:id)).to be_empty
    unqueued_job = Lev::BackgroundJob.create
    expect(described_class.unqueued.collect(&:id)).to include(unqueued_job.id)
  end

  it 'sets progress to 100% when succeeded' do
    job = described_class.new
    job.succeeded!
    expect(job.progress).to eq 1
  end

  describe '#save' do
    it 'saves the hash given and writes them to the job' do
      job.save(something: 'else')
      expect(job.something).to eq('else')
    end

    it 'prevents the use of reserved keys' do
      expect { job.save(progress: 'blocked') }.to raise_error(Lev::IllegalArgument)
      expect { job.save(id: 'blocked') }.to raise_error(Lev::IllegalArgument)
      expect { job.save(status: 'blocked') }.to raise_error(Lev::IllegalArgument)
      expect { job.save(errors: 'blocked') }.to raise_error(Lev::IllegalArgument)
    end
  end

  describe '#set_progress' do
    it 'sets the progress key on the job object' do
      job.set_progress(8, 10)
      expect(job.progress).to eq(0.8)
    end

    context 'when `out_of` is supplied' do
      it 'requires a positive `at` float or integer' do
        expect { job.set_progress(nil, 1) }.to raise_error(Lev::IllegalArgument)
        expect { job.set_progress(-1, 1) }.to raise_error(Lev::IllegalArgument)
        expect { job.set_progress(2, 5) }.not_to raise_error
      end

      it 'requires `out_of` to be greater than `at`' do
        expect { job.set_progress(15, 8) }.to raise_error(Lev::IllegalArgument)
        expect { job.set_progress(5, 10) }.not_to raise_error
      end
    end

    context 'without out_of specified' do
      it 'requires `at` to be a float between 0.0 and 1.0' do
        expect { job.set_progress(1.1) }.to raise_error(Lev::IllegalArgument)
        expect { job.set_progress(-1) }.to raise_error(Lev::IllegalArgument)
        expect { job.set_progress(0.78) }.not_to raise_error
      end
    end
  end

  describe '.find!' do
    let!(:job) { described_class.create }

    it 'does not write to store when job exists' do
      expect(described_class.store).to_not receive(:write)
      found_job = described_class.find!(job.id)
      expect(found_job.as_json).to eq(job.as_json)
    end

    it 'creates unknown jobs that are not found in the store' do
      created_job = described_class.find!('not-a-real-id')
      expect(created_job.as_json['status']).to eq('unknown')
    end
  end

  describe '.find' do
    let!(:job) { described_class.create }

    it 'finds jobs that are in the store' do
      expect(described_class.store).to_not receive(:write)
      found_job = described_class.find(job.id)
      expect(found_job.as_json).to eq(job.as_json)
    end

    it 'returns nil for jobs not in the store' do
      searched_job = described_class.find('not-a-real-id')
      expect(searched_job).to be_nil
    end
  end

  context 'exception raised' do
    before do
      lev_routine_factory('ExceptionalRoutine') { raise TypeError, 'howdy there' }
      ::ActiveJob::Base.queue_adapter = :inline
    end

    after { ::ActiveJob::Base.queue_adapter = :test }

    it 'lets exception escape, job is failed and has error details' do
      Lev.configuration.job_store.clear

      expect{ ExceptionalRoutine.perform_later }.to raise_error(TypeError)

      job = Lev::BackgroundJob.all.first

      expect(job.status).to eq Lev::BackgroundJob::STATE_FAILED

      error = job.errors.first

      expect(error["code"]).to eq "exception"
      expect(error["message"]).to eq "howdy there"
      expect(error["data"]).to be_a String
    end
  end

  context 'inline activejob mode' do
    before { ::ActiveJob::Base.queue_adapter = :inline }
    after { ::ActiveJob::Base.queue_adapter = :test }

    it 'sets job to working when called' do
      expect_any_instance_of(described_class).to receive(:working!)
      DelayedRoutine.perform_later
    end

    it 'completes the job object on completion, returning other data' do
      id = DelayedRoutine.perform_later
      job = described_class.find(id)
      expect(job.status).to eq(described_class::STATE_SUCCEEDED)
      expect(job.progress).to eq(1.0)
    end
  end
end
