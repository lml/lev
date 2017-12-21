require 'spec_helper'

RSpec.describe DelegatingRoutine do

  it "should delegate" do
    result = DelegatingRoutine.call(1,8)
    expect(result.outputs[:answer]).to eq 9
  end

  it "should delegate with assumed express_output" do
    result = DelegatingRoutine[1,8]
    expect(result).to eq 9
  end

end
