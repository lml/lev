require 'spec_helper.rb'

RSpec.describe Sprocket do

  it "should not be valid with bad inputs" do
    sprocket = Sprocket.new(integer_gt_2: 1, text_only_letters: 'abcd4')
    expect(sprocket.valid?).to eq(false)
    expect(sprocket.errors.count).to eq 2
  end

end
