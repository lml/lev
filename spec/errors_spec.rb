require 'spec_helper'

# See spec/support/models

RSpec.describe Lev::Error do
  it 'requires a :code' do
    routine('FatalBlowUp') do
      fatal_error(code: nil)
    end

    routine('NonFatalBlowUp') do
      nonfatal_error(code: nil)
    end

    expect { FatalBlowUp.call }.to raise_error(ArgumentError,
                                               'must supply a :code to Lev::Error')
    expect { NonFatalBlowUp.call }.to raise_error(ArgumentError,
                                                  'must supply a :code to Lev::Error')
  end

  it 'adds nonfatal_errors to errors' do
    routine('NonFatalError') do
      nonfatal_error(code: :nonfatal, data: 'bad data', message: 'This is bad')
    end

    result = NonFatalError.call

    expect(result.errors.flat_map(&:to_s)).to include(
      'kind: lev - code: nonfatal - data: bad data - message: This is bad'
    )
  end

  it 'transfers errors from models' do
    routine('CreateTestValidityModel') do |field|
      model = TestValidity.create(required_field: field)
      transfer_errors_from(model)
    end

    result = CreateTestValidityModel.call(nil)

    expect(result.errors).not_to be_empty
    expect(result.errors.full_messages).to eq(["Required field can't be blank"])
  end
end
