require 'spec_helper'

RSpec.describe SprocketHandler do
  it 'should return fatal error messages' do
    allow_any_instance_of(SprocketHandler).to(
      receive(:params).and_return({
        sprocket: {
          integer_gt_2: '1',
          text_only_letters: '42',
        }
      }))
    result = SprocketHandler.handle
    errors = result.errors.collect { |error| error.translate }
    expect(errors).to eq(['Code cannot be blank'])
  end

  it 'should return fatal error codes if messages are missing' do
    allow_any_instance_of(SprocketHandler).to(
      receive(:params).and_return({
        sprocket: {
          integer_gt_2: '1',
          text_only_letters: '42',
        },
        code: '1111',
      }))
    result = SprocketHandler.handle
    errors = result.errors.collect { |error| error.translate }
    expect(errors).to eq(['invalid_code'])
  end
end
