require 'spec_helper'

unless ActiveRecord::Migration.table_exists?(:models)
  ActiveRecord::Migration.create_table(:models)
end

class Model < ActiveRecord::Base; end

RSpec.describe 'Transactions' do
  before do
    stub_const 'RollBackTransactions', Class.new
    stub_const 'NestedRoutine', Class.new

    NestedRoutine.class_eval do
      lev_routine

      def exec
        raise 'Rolled back'
      end
    end

    RollBackTransactions.class_eval do
      lev_routine

      uses_routine NestedRoutine

      def exec
        Model.create!
        run(:nested_routine)
      end
    end
  end

  context 'in nested routines' do
    it 'rolls back on exceptions' do
      begin
        RollBackTransactions.call
      rescue StandardError
        expect(Model.count).to eq(0)
      end
    end
  end
end
