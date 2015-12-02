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
    routine('Subroutine', outputs: { title: :_self }) do |title|
      set(title: title)
    end

    routine('MapToNested', outputs: { title: :subroutine }) do | title|
      run(:subroutine, title)
    end

    result = MapToNested.call('nested title')

    expect(result.title).to eq('nested title')
  end

  it 'maps verbatim to nested routines' do
    routine('SuperSuperNested', outputs: { description: :_self }) {
      set(description: 'super super nested desc')
    }

    routine('SuperNested', outputs: {
                             _verbatim: { name: SuperSuperNested, as: :super }
                           }) {
      run(:super)
    }

    routine('VerbatimMe', outputs: { title: :_self, description: :super_nested }) { |t|
      set(title: t)
      run(:super_nested)
    }

    routine('GetVerbatimed', outputs: { _verbatim: :verbatim_me }) { | title|
      run(:verbatim_me, title)
    }

    result = GetVerbatimed.call('verbatim title')

    expect(result.title).to eq('verbatim title')
    expect(result.description).to eq('super super nested desc')
  end

  it 'allows constants instead of symbols' do
    routine('ClassNameMe', outputs: { title: :_self }) do
      set(title: 'Hey')
    end

    routine('ClassNameIt', outputs: { _verbatim: ClassNameMe }) do
      run(:class_name_me)
    end

    result = ClassNameIt.call
    expect(result.title).to eq('Hey')
  end

  it 'allows a set of options' do
    routine('OptionifyMe', outputs: { title: :_self }) do
      set(title: 'You used options!')
    end

    routine('OptionifyIt', outputs: {
      _verbatim: { name: OptionifyMe, as: :something_else }
    }) { run(:something_else) }

    result = OptionifyIt.call
    expect(result.title).to eq('You used options!')
  end

  it 'saves itself from no :as option' do
    routine('DontAsMeBro', outputs: { title: :_self }) do
      set(title: "Default alias used")
    end

    routine('DontAsIt', outputs: { _verbatim: { name: DontAsMeBro } }) do
      run(:dont_as_me_bro)
    end

    result = DontAsIt.call
    expect(result.title).to eq('Default alias used')
  end

  it 'plays nicely with namespaced routines' do
    routine('Name::Space::Me', outputs: { title: :_self }) do
      set(title: 'wow you made it')
    end

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

    result = UseTheNameSpaced.call
    expect(result.title).to eq('wow you made it')
  end
end
