module Lev

  class InputMapper

    def initialize(scope=nil, mapping=nil)
      @scope = scope
      @mapping = mapping
    end

    def mapping
      @mapping || {}
    end

    def map(inputs)
      inputs = [inputs].flatten.compact
      inputs.collect do |input|
        mapped = mapping[input] || input
        @scope.nil? ? mapped : [@scope, mapped].flatten
      end
    end

    # def self.passthrough
    #   Passthrough.new
    # end

    # def self.specified(mapping)
    #   Specified.new(mapping)
    # end

    # def self.scoped(scope)
    #   Scoped.new(scope)
    # end

    # def map(inputs)
    #   raise AbstractMethodCalled
    # end

    # class Passthrough < InputMapper
    #   def map(inputs); inputs; end
    # end

    # class Specified < InputMapper
    #   def initialize(mapping)
    #     raise IllegalArgument "mapping cannot be nil" if mapping.nil?
    #     @mapping = mapping
    #   end

    #   def map(inputs)
    #     inputs = [inputs].flatten.compact
    #     inputs.collect{|input| @mapping[input]}
    #   end
    # end

    # class Scoped < InputMapper
    #   def initialize(scope)
    #     raise IllegalArgument "scope cannot be nil" if scope.nil?
    #     @scope = scope
    #   end

    #   def map(inputs)
    #     inputs = [inputs].flatten.compact
    #     inputs.collect{|input| [@scope, input.flatten]}
    #   end
    # end

  end

end