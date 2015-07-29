module Lev
  class Job
    attr_reader :id

    def initialize(attrs = {})
      attrs.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def status
      @state
    end
  end
end
