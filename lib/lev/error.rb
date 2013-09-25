module Lev

  class Error

    attr_accessor :code
    attr_accessor :data
    attr_accessor :kind
    attr_accessor :message

    # An array of symbols indicating where this error came from
    attr_accessor :address

    attr_accessor :relates_to

    attr_accessor :offending_inputs

    def initialize(args={})
      raise IllegalArgument if args[:code].blank?

      self.code = args[:code]
      self.data = args[:data]
      self.kind = args[:kind]
      self.message = args[:message]
      
      # self.address = args[:address]
      # self.address = [self.address] if !(self.address.is_a? Array)

      # self.relates_to = args[:relates_to]

      self.offending_inputs = args[:offending_inputs]
    end

    def translate
      ErrorTranslator.translate(self)
    end
  end

end