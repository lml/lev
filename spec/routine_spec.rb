require 'spec_helper'

describe Lev::Routine do

  before do
    stub_const 'RaiseError', Class.new
    RaiseError.class_eval {
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
  end

  it "raised errors should propagate" do
    expect{
      RaiseArgumentError.call
    }.to raise_error
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
    }.to raise_error

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
      }.to raise_error

      begin
        RaiseFatalError.call
      rescue => e
        expect(e.message).to eq('code broken - such disaster - kind lev')
      end
    end
  end

end
