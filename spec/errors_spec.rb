require 'spec_helper'

describe Lev::Errors do

  let(:errors) { Lev::Errors.new }

  it "should raise an exception if requested and there are errors" do
    errors.add(false, kind: :lev, code: 'a code', message: 'a message')
    expect{errors.raise_exception_if_any!}.to raise_error(StandardError, 'a message')
  end

  it "should not raise an exception if requested and there aren't any errors" do
    expect{errors.raise_exception_if_any!}.not_to raise_error
  end

  it "should reraise an exception if requested and present" do
    exception = StandardError.new("a message")
    errors.add(false, kind: :exception, code: 'code', data: exception)
    expect{errors.reraise_exception!}.to raise_error(StandardError, "a message")
  end

  it "should not reraise an exception if requested and not present" do
    errors.add(false, kind: :lev, code: 'a code')
    expect{errors.reraise_exception!}.not_to raise_error
  end

end
