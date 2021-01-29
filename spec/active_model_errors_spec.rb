require 'spec_helper'

RSpec.describe 'ActiveModelErrors' do
  class DummyModel
    def self.human_attribute_name(attr, default='')
      return attr.capitalize
    end
  end

  let(:test_model) { DummyModel.new }
  let(:errors) { ActiveModel::Errors.new(test_model) }

  it 'can record errors' do
    errors.add(:foo, 'bar')
    expect(errors[:foo]).to eq ['bar']
    expect(errors.any?).to be(true)
  end

  it 'can add using strings' do
    errors.add('crash', 'is a bad bad value')
    expect(errors[:crash]).to eq ['is a bad bad value']
    expect(errors.include?('crash')).to be true
  end

  it 'duplicates when copy called' do
    model = OpenStruct.new

    error = ActiveModel::Errors.new(model)
    error.add(:code, 'error')
    expect(error[:code]).to eq ['error']

    other = ActiveModel::Errors.new(model)
    other.add(:code, 'warning')
    error.copy!(other)
    expect(error[:code]).to eq ['warning']
  end
end
