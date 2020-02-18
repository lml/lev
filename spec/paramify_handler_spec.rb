require 'spec_helper'

RSpec.describe ParamifyHandlerA do
  it 'should error out on badly formatted params' do
    result = ParamifyHandlerA.handle(params: {terms: {type: 'blah'}})
    errors = result.errors.collect { |error| error.translate }
    expect(errors).to eq(['Type is not valid'])
  end
end

RSpec.describe ParamifyHandlerB do
  it 'should error out on badly formatted ungrouped params' do
    result = ParamifyHandlerB.handle(params: {type: 'blah'})
    errors = result.errors.collect { |error| error.translate }
    expect(errors).to eq(['Type is not valid'])
  end

  it 'should provide access to top-level params' do
    result = ParamifyHandlerB.handle(params: {type: 'Name', value: 2})
    errors = result.errors.collect { |error| error.translate }
    expect(result.outputs.success).to eq true
  end
end
