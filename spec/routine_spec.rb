require 'spec_helper'

RSpec.describe Lev::Routine do

  before do
    stub_const 'RaiseRuntimeError', Class.new
    RaiseRuntimeError.class_eval {
      lev_routine
      def exec
        raise 'error message'
      end
    }

    stub_const 'RaiseStandardError', Class.new
    RaiseStandardError.class_eval {
      lev_routine
      def exec
        unknown_method_call
      end
    }

    stub_const 'RaiseArgumentError', Class.new
    RaiseArgumentError.class_eval {
      lev_routine
      def exec
        raise ArgumentError, 'your argument is invalid', caller
      end
    }
  end

  it "raised errors should propagate" do
    expect{
      RaiseArgumentError.call
    }.to raise_error(ArgumentError)
  end

  it "raised StandardErrors should propagate" do
    expect {
      RaiseStandardError.call
    }.to raise_error(NameError)
  end

  it 'allows not raising fatal errors to be overridden' do
    stub_const 'NestedFatalError', Class.new
    NestedFatalError.class_eval {
      lev_routine raise_fatal_errors: false # testing that parent overrides

      def exec
        fatal_error(code: :its_broken)
      end
    }

    stub_const 'SpecialFatalErrorOption', Class.new
    SpecialFatalErrorOption.class_eval {
      lev_routine raise_fatal_errors: true, delegates_to: NestedFatalError
    }

    stub_const 'NoFatalErrorOption', Class.new
    NoFatalErrorOption.class_eval {
      lev_routine
      def exec
        fatal_error(code: :no_propagate)
      end
    }

    Lev.configure { |c| c.raise_fatal_errors = false }

    expect {
      SpecialFatalErrorOption.call
    }.to raise_error(Lev::FatalError)

    expect {
      NoFatalErrorOption.call
    }.not_to raise_error
  end

  it 'allows raising fatal errors config to be overridden' do
    stub_const 'SpecialNoFatalErrorOption', Class.new
    SpecialNoFatalErrorOption.class_eval {
      lev_routine raise_fatal_errors: false
      def exec
        fatal_error(code: :its_broken)
      end
    }

    Lev.configure { |c| c.raise_fatal_errors = true }

    expect {
      SpecialNoFatalErrorOption.call
    }.not_to raise_error
  end

  context 'when raise_fatal_errors is configured true' do
    before do
      Lev.configure do |config|
        config.raise_fatal_errors = true
      end

      stub_const 'RaiseFatalError', Class.new
      RaiseFatalError.class_eval {
        lev_routine
        def exec
          fatal_error(code: :broken, such: :disaster)
        end
      }
    end

    after do
      Lev.configure do |config|
        config.raise_fatal_errors = false
      end
    end

    it 'raises an exception on fatal_error if configured' do
      expect {
        RaiseFatalError.call
      }.to raise_error(Lev::FatalError)

      begin
        RaiseFatalError.call
      rescue => e
        expect(e.message).to eq('code broken - such disaster - kind lev')
      end
    end
  end

  it 'does not mess up results on a transaction retry' do
    # To get the transaction to retry, we need to raise an exception the first time
    # through execution, after an output has been set in a nested routine and
    # translated to the parent routine

    stub_const 'NestedRoutine', Class.new
    NestedRoutine.class_eval {
      lev_routine
      def exec
        outputs[:test] = 1
      end
    }

    stub_const 'MainRoutine', Class.new
    MainRoutine.class_eval {
      lev_routine
      uses_routine NestedRoutine,
                   translations: {outputs: {type: :verbatim}}

      def exec
        run(NestedRoutine)

        @times_called ||= 0
        @times_called += 1
        raise(::ActiveRecord::TransactionIsolationConflict, 'hi') if @times_called == 1
      end
    }

    # In reality, the Lev routine is the top-level transaction, but rspec has its own
    # transactions at the top, so we have to fake that the Lev routine transaction
    # is at the top.
    allow(ActiveRecord::Base).to receive(:tr_in_nested_transaction?) { false }

    results = MainRoutine.call
    expect(results.outputs.test).to eq 1
  end

end
