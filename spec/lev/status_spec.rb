require 'spec_helper'

RSpec.describe Lev::Status do
  class DelayedRoutine
    lev_routine
    protected
    def exec; end
  end

  describe '.jobs' do
    it 'returns all job objects with the UUID and the status information' do
      allow(SecureRandom).to receive(:uuid) { '123abc' }

      DelayedRoutine.perform_later
      job = described_class.jobs.last

      expect(job.id).to eq('123abc')
      expect(job.status).to eq('queued')
    end
  end
end
