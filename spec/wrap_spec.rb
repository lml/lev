require 'spec_helper'

RSpec.describe 'Lev Routine Wrapping' do
  it 'wraps a single model' do
    lev_routine_factory('WrappingRoutine', wraps: WrappedModel,
                                           exposes: [:title, :description]) do
      create_instance(:wrapped_model, title: 'Hello',
                                      description: 'World',
                                      do_not_expose_me: 'No')
    end

    result = WrappingRoutine.call

    expect(result.title).to eq('Hello')
    expect(result.description).to eq('World')
    expect(result).not_to respond_to(:do_not_expose_me)
  end

  it 'wraps multiple models' do
    lev_routine_factory('WrappingRoutine', wraps: [WrappedModel, OtherWrapped],
                                           exposes: { title: :wrapped_model,
                                                      description: :wrapped_model,
                                                      price: :other_wrapped }) do
      create_instance(:wrapped_model, title: 'Hello',
                                      description: 'World',
                                      do_not_expose_me: 'No')
      create_instance(:other_wrapped, price: 10, no_way: 'No no no way')
    end

    result = WrappingRoutine.call

    expect(result.title).to eq('Hello')
    expect(result.description).to eq('World')
    expect(result.price).to eq(10)
    expect(result).not_to respond_to(:do_not_expose_me)
    expect(result).not_to respond_to(:no_way)
  end
end
