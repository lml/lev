require 'spec_helper'

RSpec.describe Lev::Result do
  it 'contains any validity errors' do
    pending
    lev_routine_factory('ValidityRoutine', wraps: TestValidity,
                                           readable: :required_field) do |field|
      puts field
      create_instance(required_field: field)
    end

    result = ValidityRoutine.call(nil)

    error_msg = result.errors.full_messages.first
    expect(error_msg).to eq('Required field cannot be blank.')
  end
end
