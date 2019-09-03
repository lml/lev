require 'spec_helper'

RSpec.describe 'BetterActiveModelErrors' do
  class DummyModel
    def self.human_attribute_name(attr, default='')
      return attr.capitalize
    end
  end

  let(:test_model) { DummyModel.new }
  let(:errors) { Lev::BetterActiveModelErrors.new(test_model) }

  it 'can record errors' do
    errors[:foo] = 'bar'
    expect(errors.any?).to be(true)
  end

  it 'can add using strings' do
    errors.add('crash', 'is a bad bad value')
    expect(errors[:crash]).to eq ['is a bad bad value']
    expect(errors.include?('crash')).to be true
  end

  it 'duplicates when copy called' do
    model = OpenStruct.new

    error = Lev::BetterActiveModelErrors.new(model)
    error.set(:code, 'error')
    expect(error.get(:code)).to eq 'error'

    other = Lev::BetterActiveModelErrors.new(model)
    other.set(:code, 'warning')
    error.copy!(other)
    expect(error.get(:code)).to eq 'warning'
  end
end
