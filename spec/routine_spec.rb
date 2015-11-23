require 'spec_helper'

describe Lev::Routine do
  before do
    lev_routine_factory('RaiseError') { raise 'error message' }
    lev_routine_factory('RaiseStandardError') { unknown_method_call }
  end

  it "propagates raised errors" do
    expect{ RaiseArgumentError.call }.to raise_error
  end

  it "propagates raised StandardErrors" do
    expect { RaiseStandardError.call }.to raise_error(NameError)
  end

  it 'overrides the raise_fatal_errors config' do
    lev_routine_factory('SpecialNoFatalErrorOption', raise_fatal_errors: false) do
      fatal_error(code: :its_broken)
    end

    Lev.configure { |c| c.raise_fatal_errors = true }

    expect { SpecialNoFatalErrorOption.call }.not_to raise_error
  end

  context 'when raise_fatal_errors is configured true' do
    before do
      Lev.configure { |config| config.raise_fatal_errors = true }
      lev_routine_factory('RaiseFatalError') { fatal_error(code: :broken, such: :disaster) }
    end

    after do
      Lev.configure { |config| config.raise_fatal_errors = false }
    end

    it 'raises an exception on fatal_error' do
      expect { RaiseFatalError.call }.to raise_error

      begin
        RaiseFatalError.call
      rescue => e
        expect(e.message).to eq('code broken - such disaster - kind lev')
      end
    end
  end
end
