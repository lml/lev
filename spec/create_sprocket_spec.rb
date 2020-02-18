require 'spec_helper'

RSpec.describe CreateSprocket do

  it "should transfer errors appropriately" do
    result = CreateSprocket.call(1,"42")
    errors = result.errors.collect { |error| error.translate }
    expect(errors).to eq([
      'Integer gt 2 must be greater than or equal to 3',
      'Text only letters can only contain letters',
    ])
  end

end
