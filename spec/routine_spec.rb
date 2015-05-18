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

    stub_const 'RaiseFatalError', Class.new
    RaiseFatalError.class_eval {
      lev_routine
      def exec
        fatal_error(code: :broken, such: :disaster)
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

  it 'raises an exception on fatal_error if configured' do
    Lev.configure do |config|
      config.raise_fatal_errors = true
    end

    expect {
      RaiseFatalError.call
    }.to raise_error

    begin
      RaiseFatalError.call
    rescue => e
      expect(e.message).to eq('code broken - such disaster')
    end
  end

end
