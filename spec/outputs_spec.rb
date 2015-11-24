require 'spec_helper'

RSpec.describe 'Outputs interfaces' do
  it 'maps attributes to itself' do
    routine('MapToMyself', outputs: { title: :_self }) do |title|
      set(title: title)
    end

    result = MapToMyself.call('my title')

    expect(result.title).to eq('my title')
  end

  it 'does not allow setting attributes not defined' do
    routine('SetNonexistent', outputs: { title: :_self }) do |title|
      set(nope: title)
    end

    expect { SetNonexistent.call('my title') }.to raise_error
  end

  it 'maps attributes from nested routines' do
    routine('NestedRoutine', outputs: { title: :_self }) do |title|
      set(title: title)
    end

    routine('MapToNested', outputs: { title: :nested_routine }) do | title|
      run(:nested_routine, title)
    end

    result = MapToNested.call('nested title')

    expect(result.title).to eq('nested title')
  end

  it 'maps verbatim to nested routines' do
    routine('SuperSuperNested', outputs: { description: :_self }) do
      set(description: 'something')
    end

    routine('SuperNested', outputs: { _verbatim: { name: SuperSuperNested, as: :super },
                                                   description: :_self }) do
      run(:super)
      set(description: 'super nested desc')
    end

    routine('VerbatimMe', outputs: { title: :_self,
                                     description: :super_nested }) do |title|
      set(title: title)
      run(:super_nested)
    end

    routine('GetVerbatimed', outputs: { _verbatim: :verbatim_me }) do | title|
      run(:verbatim_me, title)
    end

    result = GetVerbatimed.call('verbatim title')

    expect(result.title).to eq('verbatim title')
    expect(result.description).to eq('super nested desc')
  end

  it 'allows constants instead of symbols' do
    routine('ClassNameMe')

    routine('ClassNameIt', outputs: { _verbatim: ClassNameMe }) do
      run(:class_name_me)
    end

    expect(ClassNameMe).to receive(:call)

    ClassNameIt.call
  end

  it 'allows a set of options' do
    routine('OptionifyMe')

    routine('OptionifyIt', outputs: {
      _verbatim: { name: OptionifyMe, as: :something_else }
    }) { run(:something_else) }

    expect(OptionifyMe).to receive(:call)

    OptionifyIt.call
  end

  it 'saves itself from no :as option' do
    routine('DontAsMeBro')

    routine('DontAsIt', outputs: { _verbatim: { name: DontAsMeBro } }) do
      run(:dont_as_me_bro)
    end

    expect(DontAsMeBro).to receive(:call)

    DontAsIt.call
  end

  it 'plays nicely with namespaced routines' do
    routine('Name::Space::Me', outputs: { title: :_self })

    routine('Name::Space::MeTwo', outputs: { _verbatim: Name::Space::Me }) do
      run(:name_space_me)
    end

    routine('Name::Space::MeThree')

    routine('UseTheNameSpaced', outputs: {
      _verbatim: [{ name: Name::Space::MeTwo, as: :coolio }, Name::Space::MeThree]
    }) do
      run(:coolio)
      run(:name_space_me_three)
    end
    p UseTheNameSpaced.nested_routines

    expect(Name::Space::Me).to receive(:call)
    expect(Name::Space::MeTwo).to receive(:call)
    expect(Name::Space::MeThree).to receive(:call)

    UseTheNameSpaced.call
  end
end
