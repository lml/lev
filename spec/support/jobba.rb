require 'jobba'

module Lev::Jobba

  def self.use_jobba
    Lev.configure do |config|
      config.create_status_proc = ->(*) { Jobba::Status.create! }
      config.find_status_proc = ->(id) { Jobba::Status.find!(id) }
    end
    true
  end

end
