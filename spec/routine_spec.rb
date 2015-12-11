require 'spec_helper'

describe Lev::Routine do
  before do
    routine('RaiseError') { raise 'error message' }
    routine('RaiseStandardError') { unknown_method_call }
  end

  it "propagates raised errors" do
    expect{ RaiseArgumentError.call }.to raise_error(NameError)
  end

  it "propagates raised StandardErrors" do
    expect { RaiseStandardError.call }.to raise_error(NameError)
  end

  it 'overrides the raise_fatal_errors config' do
    routine('SpecialNoFatalErrorOption', raise_fatal_errors: false) do
      fatal_error(code: :its_broken)
    end

    Lev.configure { |c| c.raise_fatal_errors = true }

    expect { SpecialNoFatalErrorOption.call }.not_to raise_error
  end

  context 'when raise_fatal_errors is configured true' do
    before(:all) do
      Lev.configure { |config| config.raise_fatal_errors = true }
    end

    after(:all) do
      Lev.configure { |config| config.raise_fatal_errors = false }
    end

    it 'raises an exception on fatal_error' do
      routine('RaiseFatalError') { fatal_error(code: :broken,
                                               such: :disaster,
                                               really: 'bad') }

      expect { RaiseFatalError.call }.to raise_error(Lev::FatalError)

      begin
        RaiseFatalError.call
      rescue => e
        expect(e.message).to eq('kind: lev - code: broken - such: disaster - really: bad')
      end
    end
  end

  it 'allows [] as an alias to .call' do
    routine('ShortenedCall', outputs: { shortened: :_self }) do
      set(shortened: 'great')
    end

    result = ShortenedCall[]

    expect(result.shortened).to eq('great')
  end

  it 'adds to result attributes' do
    routine('AddToResult', outputs: { add_me: :_self }) do
      result_set(add_me: 2)
      result_add(add_me: 3)
    end

    routine = AddToResult.call

    expect(routine.add_me).to eq(5)
  end

  it 'pushes on result attributes' do
    routine('PushToResult', outputs: { push_me: :_self }) do
      result_set(push_me: [1])
      result_push(push_me: 3)
    end

    routine = PushToResult.call

    expect(routine.push_me).to eq([1, 3])
  end
end
