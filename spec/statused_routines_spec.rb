require 'active_job'
require 'spec_helper'

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = ::Logger.new(nil)

RSpec.describe 'Statused Routines' do
  subject(:status) { Lev::Status.new }

  context 'in a routine' do
    it 'works so wonderfully' do
      stub_const 'StatusedRoutine', Class.new
      StatusedRoutine.class_eval do
        lev_routine
        protected
        def exec
          set_progress(9, 10)
        end
      end

      outputs = StatusedRoutine.perform_later.outputs
      expect(outputs.status[:progress]).to eq(0.9)
    end
  end

  describe '#save' do
    it 'prevents the use of reserved keys' do
      expect {
        status.save(progress: 'blocked')
      }.to raise_error(Lev::IllegalArgument)

      expect {
        status.save(uuid: 'blocked')
      }.to raise_error(Lev::IllegalArgument)

      expect {
        status.save(status: 'blocked')
      }.to raise_error(Lev::IllegalArgument)

      expect {
        status.save(errors: 'blocked')
      }.to raise_error(Lev::IllegalArgument)
    end

    it 'saves the hash given and writes them to the status' do
      status.save(something: 'else')
      expect(status.get('something')).to eq('else')
    end
  end

  describe '#add_error' do
    it 'adds the error object data to the status object' do
      errors = Lev::Error.new(code: 'bad', message: 'awful')
      status.add_error(errors)
      expect(status.get('errors')).to eq([{ 'is_fatal' => false,
                                            'code' => 'bad',
                                            'message' => 'awful' }])
    end
  end

  describe 'dynamic status setters/getters' do
    it 'is queued' do
      expect(status).not_to be_queued
      status.queued!
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
  end

  describe '#set_progress' do
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
