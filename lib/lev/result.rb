module Lev
  class Result
    attr_reader :errors

    def initialize(wrapped, errors, exposes = {})
      @wrapped = [wrapped].flatten
      @errors = errors
      self.class.define_exposed_methods(wrapped, exposes)
    end

    def self.define_exposed_methods(wrapped, exposes)
      case exposes
      when Hash
        exposes.each do |attr, model|
          model_klass = select_wrapped(wrapped, model)
          define_method(attr) { model_klass.send(attr) }
        end
      when Array
        exposes.each do |attr|
          define_method(attr) { wrapped.first.send(attr) }
        end
      end
    end

    private
    def self.select_wrapped(wrapped_instances, model)
      wrapped_instances.select { |w| w.class.name.underscore == model.to_s }.first
    end
  end
end
