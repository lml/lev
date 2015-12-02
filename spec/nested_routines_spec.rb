require 'spec_helper'

RSpec.describe 'Nested routines' do
  it 'can specify nested routines as a lev_routine option' do
    routine('NestMe')

    routine('ParentMe', uses: :nest_me) do
      run(:nest_me)
    end

    expect_any_instance_of(NestMe).to receive(:call)
    ParentMe.call
  end

  it 'allows constants' do
    routine('ConstantNestMe')

    routine('ConstantParentMe', uses: ConstantNestMe) do
      run(:constant_nest_me)
    end

    expect_any_instance_of(ConstantNestMe).to receive(:call)
    ConstantParentMe.call
  end

  it 'allows the options' do
    routine('OptionUseMe')

    routine('OptionUseIt', uses: { name: OptionUseMe, as: :use_me }) do
      run(:use_me)
    end

    expect_any_instance_of(OptionUseMe).to receive(:call)
    OptionUseIt.call
  end

  it 'saves itself from no :as' do
    routine('NoAsHere')
    routine('AsItUp')

    routine('NoAsThere', uses: [{ name: NoAsHere }, { name: AsItUp, as: :up }]) do
      run(:no_as_here)
      run(:up)
    end

    expect_any_instance_of(NoAsHere).to receive(:call)
    expect_any_instance_of(AsItUp).to receive(:call)

    NoAsThere.call
  end

  it 'plays nice with namespaces' do
    routine('Name::SpaceChild')

    routine('HasNameSpace', uses: [{ name: Name::SpaceChild }]) do
      run(:name_space_child)
    end

    expect_any_instance_of(Name::SpaceChild).to receive(:call)

    HasNameSpace.call
  end
end
