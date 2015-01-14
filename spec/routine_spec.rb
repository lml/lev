require 'spec_helper'

describe Lev::Routine do

  before do
    stub_const 'RaiseArgumentError', Class.new
    RaiseArgumentError.class_eval { 
      lev_routine 
      def exec
        raise ArgumentError, 'a message'
      end
    }
  end
  
  it "should convert exceptions to fatal errors" do
    outcome = RaiseArgumentError.call
    expect(outcome.errors.count).to eq 1
    expect(outcome.errors.first.kind).to eq :exception
  end

  it "should be able to reraise an exception" do
    outcome = RaiseArgumentError.call
    expect(outcome.errors.count).to eq 1
    expect{outcome.errors.reraise_exception!}.to raise_error(ArgumentError, 'a message')
  end

end
