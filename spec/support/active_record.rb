require 'active_record'

ActiveRecord::Base.establish_connection(adapter: :sqlite3, database: ':memory:')

unless ActiveRecord::Migration.table_exists?(:test_validities)
  ActiveRecord::Migration.create_table(:test_validities) do |t|
    t.string :required_field
  end
end

unless ActiveRecord::Migration.table_exists?(:wrapped_models)
  ActiveRecord::Migration.create_table(:wrapped_models) do |t|
    t.string :title
    t.string :description
    t.string :do_not_expose_me
  end
end

unless ActiveRecord::Migration.table_exists?(:other_wrappeds)
  ActiveRecord::Migration.create_table(:other_wrappeds) do |t|
    t.integer :price
    t.string :no_way
  end
end
