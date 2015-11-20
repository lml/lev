require 'spec_helper'

RSpec.describe 'Manifest interfaces' do
  it 'maps attributes to itself' do
    lev_routine_factory('MapToMyelf', manifest: { title: :_self }) do |title|
      set(title: title)
    end

    result = MapToMyelf.call('my title')

    expect(result.title).to eq('my title')
  end

  it 'does not allow setting attributes not defined' do
    lev_routine_factory('SetNonexistent', manifest: { title: :_self }) do |title|
      set(nope: title)
    end

    expect { SetNonexistent.call('my title') }.to raise_error
  end

  it 'maps attributes from nested routines' do
    lev_routine_factory('NestedRoutine') do |title|
      set(title: title)
    end

    lev_routine_factory('MapToNested', manifest: { title: :nested_routine }) do | title|
      run(:nested_routine, title)
    end

    result = MapToNested.call('nested title')

    expect(result.title).to eq('nested title')
  end

  it 'maps verbatim to nested routines'
end
