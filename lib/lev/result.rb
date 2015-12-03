module Lev
  class Result
    attr_accessor :errors

    def initialize(outputs, errors)
      @errors = errors
      self.class.outputs(outputs)
    end

    def set(attrs = {})
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def self.outputs(map)
      map.each do |attribute, source|
        attr_reader attribute

        define_method("#{attribute}=") do |value|
          instance_variable_set("@#{attribute}", value)
        end

        private "#{attribute}="
      end
    end
  end
end
