require 'spec_helper'

RSpec.describe Lev::Query do
  it 'returns a value on call' do
    query('AreTheseEqual') do |arg1, arg2|
      arg1 == arg2
    end

    expect(AreTheseEqual.call(1, 1)).to be true
    expect(AreTheseEqual.call(1, 2)).to be false
  end
end
