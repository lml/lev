require 'spec_helper'

RSpec.describe 'Transactions' do
  before do
    lev_routine_factory('NestedRoutine') { raise 'Rolled back' }
    lev_routine_factory('RollBackTransactions') do
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
