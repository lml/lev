require 'active_record'
require './spec/support/capture_stdout_helper'

ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: ':memory:')

class LevSupportMigration < ActiveRecord::Migration
  extend CaptureStdoutHelper

  capture_stdout do
    create_table(:test_validities) do |t|
      t.string :required_field
    end unless table_exists?(:test_validities)

    create_table(:models) unless table_exists?(:models)
  end
end
