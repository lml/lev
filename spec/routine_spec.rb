require 'spec_helper'

describe Lev::Routine do
  before do
    lev_routine_factory('RaiseError') { raise 'error message' }
    lev_routine_factory('RaiseStandardError') { unknown_method_call }
  end

  it "raised errors should propagate" do
    expect{ RaiseArgumentError.call }.to raise_error
  end

  it "raised StandardErrors should propagate" do
    expect { RaiseStandardError.call }.to raise_error(NameError)
  end

  it 'allows not raising fatal errors to be overridden' do
    lev_routine_factory('NestedFatalError') { fatal_error(code: :its_broken) }

    lev_routine_factory('SpecialFatalErrorOption', raise_fatal_errors: true,
                                                   delegates_to: NestedFatalError)

    lev_routine_factory('NoFatalErrorOption') { fatal_error(code: :no_propagate) }

    Lev.configure { |c| c.raise_fatal_errors = false }

    expect { SpecialFatalErrorOption.call }.to raise_error

    expect { NoFatalErrorOption.call }.not_to raise_error
  end

  it 'allows raising fatal errors config to be overridden' do
    lev_routine_factory('SpecialNoFatalErrorOption', raise_fatal_errors: false) do
      fatal_error(code: :its_broken)
    end

    Lev.configure { |c| c.raise_fatal_errors = true }

    expect { SpecialNoFatalErrorOption.call }.not_to raise_error
  end

  context 'when raise_fatal_errors is configured true' do
    before do
      Lev.configure do |config|
        config.raise_fatal_errors = true
      end

      lev_routine_factory('RaiseFatalError') { fatal_error(code: :broken, such: :disaster) }
    end

    after do
      Lev.configure do |config|
        config.raise_fatal_errors = false
      end
    end

    it 'raises an exception on fatal_error if configured' do
      expect { RaiseFatalError.call }.to raise_error

      begin
        RaiseFatalError.call
      rescue => e
        expect(e.message).to eq('code broken - such disaster - kind lev')
      end
    end
  end
end
