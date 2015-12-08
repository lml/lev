require 'spec_helper'

RSpec.describe Lev::HandleWith do
  it 'acts like a routine' do
    routine('SubRoutine', outputs: { description: :_self }) do
      set(description: 'Subroutine description')
    end

    routine('OtherSub')

    handler('TestHandler', outputs: { title: :_self,
                                      _verbatim: SubRoutine },
                           uses: OtherSub) do
      run(:other_sub)
      run(:sub_routine)
      set(title: 'Handler Title')
    end

    handler_result = TestHandler.call

    expect(handler_result.title).to eq('Handler Title')
    expect(handler_result.description).to eq('Subroutine description')
  end

  it 'paramifies' do
    handler('ParamedHandler')

    ParamedHandler.paramify :search do
      attribute :term
    end

    handler = ParamedHandler.new
    handler.send("params=", { search: { term: 'query', other: 'not here' } })

    expect(handler.search_params.term).to eq('query')
    expect(handler.search_params).not_to respond_to(:other)
  end
end
