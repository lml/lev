require 'spec_helper'

RSpec.describe Lev::Status do
  class DelayedRoutine
    lev_routine
    protected
    def exec; end
  end

  subject(:job) { described_class.all.last }

  before do
    Lev.configuration.status_store.clear
    allow(SecureRandom).to receive(:uuid) { '123abc' }
    DelayedRoutine.perform_later
  end

  it 'behaves as a nice ruby object' do
    expect(job.id).to eq('123abc')
    expect(job.status).to eq(Lev::Status::STATE_QUEUED)
    expect(job.progress).to eq(0.0)
  end

  it 'is unknown when not found' do
    foo = described_class.find('noooooo')
    expect(foo.status).to eq(Lev::Status::STATE_UNKNOWN)
  end

  it 'uses as_json' do
    json = job.as_json

    expect(json).to eq({
      'id' => '123abc',
      'status' => Lev::Status::STATE_QUEUED,
      'progress' => 0.0,
      'errors' => []
    })

    job.save(foo: :bar)
    json = job.as_json

    expect(json['foo']).to eq('bar')
  end
end
