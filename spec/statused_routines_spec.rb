require 'spec_helper'

RSpec.describe 'Statused Routines' do
  subject(:status) { Lev::Status.new }

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
    it 'requires a positive `at` integer value' do

      expect {
        status.set_progress(nil)
      }.to raise_error(Lev::IllegalArgument)

      expect {
        status.set_progress(-1)
      }.to raise_error(Lev::IllegalArgument)

      expect {
        status.set_progress(1)
      }.not_to raise_error
    end

    it 'requires `out_of` to be greater than `at` if set' do
      expect {
        status.set_progress(15, 8)
      }.to raise_error(Lev::IllegalArgument)

      expect {
        status.set_progress(5, 10)
      }.not_to raise_error
    end
  end
end
