require 'spec_helper'

describe Lev::BackgroundJob do

  context 'delayed routine' do
    before { stub_lev_routine('DelayedRoutine') }

    subject(:job) { described_class.all.last }

    before do
      Lev.configuration.job_store.clear
      allow(SecureRandom).to receive(:uuid) { '123abc' }
      DelayedRoutine.perform_later
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
      json = job.as_json

      expect(json).to eq({
        'id' => '123abc',
        'status' => described_class::STATE_QUEUED,
        'progress' => 0.0,
        'errors' => []
      })

      job.save(foo: :bar)
      json = job.as_json

      expect(json['foo']).to eq('bar')
    end

    it 'generates attributes for custom variables' do
      job.save(foo: 'bar')

      reloaded_job = Lev::BackgroundJob.find(job.id)

      expect(reloaded_job.respond_to?(:foo)).to be true
      expect(reloaded_job.foo).to eq('bar')
    end

    it 'has scopes' do
      expect(described_class.incomplete.collect(&:id)).to include(job.id)

      job.queued!
      expect(described_class.incomplete.collect(&:id)).to include(job.id)
      expect(described_class.queued.collect(&:id)).to include(job.id)

      job.working!
      expect(described_class.incomplete.collect(&:id)).to include(job.id)
      expect(described_class.working.collect(&:id)).to include(job.id)

      job.failed!
      expect(described_class.incomplete.collect(&:id)).not_to include(job.id)
      expect(described_class.failed.collect(&:id)).to include(job.id)

      job.killed!
      expect(described_class.incomplete.collect(&:id)).to include(job.id)
      expect(described_class.killed.collect(&:id)).to include(job.id)

      job.unknown!
      expect(described_class.incomplete.collect(&:id)).to include(job.id)
      expect(described_class.unknown.collect(&:id)).to include(job.id)

      job.succeeded!
      expect(described_class.succeeded.collect(&:id)).to include(job.id)
      expect(described_class.incomplete.collect(&:id)).not_to include(job.id)
      expect(described_class.succeeded.collect(&:id)).to include(job.id)
    end

    it 'has the unqueued scope' do
      expect(described_class.unqueued.collect(&:id)).to eq []
      unqueued_job = Lev::BackgroundJob.create
      expect(described_class.unqueued.collect(&:id)).to include(unqueued_job.id)
    end
  end

  it 'sets progress to 100% when succeeded' do
    job = described_class.new
    job.succeeded!
    expect(job.progress).to eq 1
  end

  describe '.find!' do
    let!(:job) { described_class.create }

    it 'does not write to store when job exists' do
      expect(described_class.store).to_not receive(:write)
      found_job = described_class.find!(job.id)
      expect(found_job.as_json).to eq(job.as_json)
    end

    it 'finds jobs that are not in the store' do
      found_job = described_class.find!('not-a-real-id')
      expect(found_job.as_json).to include('status' => 'unknown')
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
      found_job = described_class.find('still-not-a-real-id')
      expect(found_job).to be_nil
    end
  end

end
