module Lev
  class Error
    attr_accessor :code, :data, :kind, :message, :offending_inputs

    def initialize(args = {})
      raise ArgumentError, "must supply a :code" if args[:code].blank?

      self.code = args[:code]
      self.data = args[:data]
      self.kind = args[:kind]
      self.message = args[:message]
      self.offending_inputs = args[:offending_inputs]
    end

    def to_s
      inspect
    end
  end
end
