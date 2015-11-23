require 'spec_helper'

RSpec.describe 'Nested routines' do
  it 'can specify nested routines as a lev_routine option' do
    lev_routine_factory('NestMe')

    lev_routine_factory('ParentMe', uses: :nest_me) do
      run(:nest_me)
    end

    expect(NestMe).to receive(:call)
    ParentMe.call
  end

  it 'allows constants' do
    lev_routine_factory('ConstantNestMe')

    lev_routine_factory('ConstantParentMe', uses: ConstantNestMe) do
      run(:constant_nest_me)
    end

    expect(ConstantNestMe).to receive(:call)
    ConstantParentMe.call
  end

  it 'allows the options' do
    lev_routine_factory('OptionUseMe')

    lev_routine_factory('OptionUseIt', uses: { name: OptionUseMe, as: :use_me }) do
      run(:use_me)
    end

    expect(OptionUseMe).to receive(:call)
    OptionUseIt.call
  end

  it 'saves itself from no :as' do
    lev_routine_factory('NoAsHere')
    lev_routine_factory('AsItUp')

    lev_routine_factory('NoAsThere', uses: [{ name: NoAsHere },
                                            { name: AsItUp, as: :up }]) do
      run(:no_as_here)
      run(:up)
    end

    expect(NoAsHere).to receive(:call)
    expect(AsItUp).to receive(:call)

    NoAsThere.call
  end

  it 'plays nice with namespaces' do
    lev_routine_factory('Name::SpaceChild')

    lev_routine_factory('HasNameSpace', uses: [{ name: Name::SpaceChild }]) do
      run(:name_space_child)
    end

    expect(Name::SpaceChild).to receive(:call)

    HasNameSpace.call
  end
end
