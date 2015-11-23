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

  it 'allows constants instead of symbols' do
    lev_routine_factory('ClassNameMe')

    lev_routine_factory('ClassNameIt', outputs: { _verbatim: ClassNameMe }) do
      run(:class_name_me)
    end

    expect(ClassNameMe).to receive(:call)

    ClassNameIt.call
  end

  it 'allows a set of options' do
    lev_routine_factory('OptionifyMe')

    lev_routine_factory('OptionifyIt', outputs: {
      _verbatim: { name: OptionifyMe, as: :something_else }
    }) { run(:something_else) }

    expect(OptionifyMe).to receive(:call)

    OptionifyIt.call
  end

  it 'saves itself from no :as option' do
    lev_routine_factory('DontAsMeBro')

    lev_routine_factory('DontAsIt', outputs: { _verbatim: { name: DontAsMeBro } }) do
      run(:dont_as_me_bro)
    end

    expect(DontAsMeBro).to receive(:call)

    DontAsIt.call
  end

  it 'plays nicely with namespaced routines' do
    lev_routine_factory('Name::Space::Me')
    lev_routine_factory('Name::Space::MeTwo')

    lev_routine_factory('UseTheNameSpaced', outputs: {
      _verbatim: [{ name: Name::Space::Me, as: :coolio }, Name::Space::MeTwo]
    }) do
      run(:coolio)
      run(:name_space_me_two)
    end

    expect(Name::Space::Me).to receive(:call)
    expect(Name::Space::MeTwo).to receive(:call)

    UseTheNameSpaced.call
  end
end
