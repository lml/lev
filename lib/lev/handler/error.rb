module Lev::Handler

  class Error
    # need a type or source that can be :activerecord
    # when activerecord, data should contain specific fields that
    # can be used by generate_message in BetterErrors
    attr_accessor :code
    attr_accessor :data
    attr_accessor :kind
    attr_accessor :message
    attr_accessor :offending_params

    def initialize(args={})
      raise IllegalArgument if args[:code].blank?

      self.code = args[:code]
      self.data = args[:data]
      self.kind = args[:kind]
      self.message = args[:message]
      
      self.offending_params = args[:offending_params]
      self.offending_params = [self.offending_params] if !(self.offending_params.is_a? Array)
    end

    def translate
      ErrorTranslator.translate(self)
    end
  end

end