require 'spec_helper'

describe CreateSprocket do
  
  it "should transfer errors appropriately" do
    results, errors = CreateSprocket.call(1,"42")
  end

end