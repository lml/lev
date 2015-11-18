require 'spec_helper'

unless ActiveRecord::Migration.table_exists?(:models)
  ActiveRecord::Migration.create_table(:models)
end

class Model < ActiveRecord::Base; end

RSpec.describe 'Transactions' do
  before do
    stub_lev_routine('NestedRoutine') do
      raise 'Rolled back'
    end

    stub_lev_routine('RollBackTransactions', uses: NestedRoutine) do
      Model.create!
      run(:nested_routine)
    end
  end

  context 'in nested routines' do
    it 'rolls back on exceptions' do
      expect {
        RollBackTransactions.call
      }.to raise_error

      expect(Model.count).to eq(0)
    end
  end
end
