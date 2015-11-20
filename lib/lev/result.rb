module Lev
  class Result
    attr_reader :errors

    def initialize(manifest, errors)
      @errors = errors
      self.class.manifest(manifest)
    end

    def set(attrs = {})
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def self.manifest(map)
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
