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
    expect(subject.id).to eq('123abc')
    expect(subject.status).to eq(Lev::Status::STATE_QUEUED)
    expect(subject.progress).to eq(0.0)
  end

  it 'is unknown when not found' do
    foo = described_class.find('noooooo')
    expect(foo.status).to eq(Lev::Status::STATE_UNKNOWN)
  end
end
