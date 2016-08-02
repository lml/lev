module Lev

  class Error

    attr_accessor :code
    attr_accessor :data
    attr_accessor :kind
    attr_accessor :message

    # The inputs related to this error
    attr_accessor :offending_inputs

    def initialize(args={})
      raise ArgumentError, "must supply a :code" if args[:code].blank?

      self.code = args[:code]
      self.data = args[:data]
      self.kind = args[:kind]
      self.message = args[:message]
      self.offending_inputs = args[:offending_inputs]
    end

    def translate
      ErrorTranslator.translate(self)
    end

    def to_s
      inspect
    end

    def full_message
      attribute = data[:attribute] if data.present?
      return message.humanize if attribute.nil?

      attr_name = attribute.to_s.gsub('.', '_').humanize

      model = data[:model]
      attr_name = model.class.human_attribute_name(attribute, default: attr_name) if model.present?

      I18n.t(:"errors.format", {
        default:   "%{attribute} %{message}",
        attribute: attr_name,
        message:   message
      })
    end

  end

end
