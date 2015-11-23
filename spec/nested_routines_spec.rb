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
end
