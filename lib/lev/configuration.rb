module Lev
  class Configuration
    attr_accessor :raise_fatal_errors, :job_store, :job_store_namespace

    def initialize
      @raise_fatal_errors = false
      @job_store = Lev::MemoryStore.new
      @job_store_namespace = :lev_job
    end
  end
end
