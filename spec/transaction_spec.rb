require 'spec_helper'

RSpec.describe 'Transactions' do
  before do
    routine('NestedRoutine') { raise 'Rolled back' }
    routine('RollBackTransactions') do
      Model.create!
      run(:nested_routine)
    end
  end

  context 'in nested routines' do
    it 'rolls back on exceptions' do
      expect { RollBackTransactions.call }.to raise_error
      expect(Model.count).to eq(0)
    end
  end
end
