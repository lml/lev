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

end
