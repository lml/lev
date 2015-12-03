require 'spec_helper'

# See spec/support/models

RSpec.describe Lev::Error do
  before do
    routine('CreateTestValidityModel') do |field|
      model = TestValidity.create(required_field: field)

      transfer_errors_from(model)
    end
  end

  it 'transfers errors from models' do
    result = CreateTestValidityModel.call(nil)

    expect(result.errors).not_to be_empty
    expect(result.errors.full_messages).to eq(["Required field can't be blank"])
  end
end
