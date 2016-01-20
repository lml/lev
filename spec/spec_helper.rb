# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'active_job'

ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = ::Logger.new(nil)

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

require 'lev'
require 'byebug'

require 'transaction_retry'
TransactionRetry.apply_activerecord_patch

Dir[(File.expand_path('../support', __FILE__)) + ("/**/*.rb")].each { |f| require f }

ActiveRecord::Base.establish_connection(
  adapter: :sqlite3,
  database: ':memory:',
)
ActiveRecord::ConnectionAdapters::SQLiteAdapter = ActiveRecord::ConnectionAdapters::SQLite3Adapter
TransactionIsolation.apply_activerecord_patch

unless Sprocket.table_exists?
  ActiveRecord::Schema.define do
    create_table 'sprockets', force: true do |t|
      t.integer 'integer_gt_2'
      t.string 'text_only_letters'
    end
  end
end

I18n.enforce_available_locales = true
