module Lev
  class Job
    attr_reader :id, :status

    def initialize(id)
      @id = id
      @status = Status.find(id)['state']
    end
  end
end
