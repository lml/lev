require 'spec_helper'

RSpec.describe 'Outputs interfaces' do
  it 'maps attributes to itself' do
    lev_routine_factory('MapToMyself', outputs: { title: :_self }) do |title|
      set(title: title)
    end

    result = MapToMyself.call('my title')

    expect(result.title).to eq('my title')
  end

  it 'does not allow setting attributes not defined' do
    lev_routine_factory('SetNonexistent', outputs: { title: :_self }) do |title|
      set(nope: title)
    end

    expect { SetNonexistent.call('my title') }.to raise_error
  end

  it 'maps attributes from nested routines' do
    lev_routine_factory('NestedRoutine', outputs: { title: :_self }) do |title|
      set(title: title)
    end

    lev_routine_factory('MapToNested', outputs: { title: :nested_routine }) do | title|
      run(:nested_routine, title)
    end

    result = MapToNested.call('nested title')

    expect(result.title).to eq('nested title')
  end

  it 'maps verbatim to nested routines' do
    lev_routine_factory('SuperNested', outputs: { description: :_self }) do
      set(description: 'super nested desc')
    end

    lev_routine_factory('VerbatimMe', outputs: { title: :_self,
                                                  description: :super_nested }) do |title|
      set(title: title)
      run(:super_nested)
    end

    lev_routine_factory('GetVerbatimed', outputs: { _verbatim: :verbatim_me }) do | title|
      run(:verbatim_me, title)
    end

    result = GetVerbatimed.call('verbatim title')

    expect(result.title).to eq('verbatim title')
    expect(result.description).to eq('super nested desc')
  end
end
