module Lev

  class ErrorTranslator

    def self.translate(error)
      case error.kind
      when :activerecord
        attribute = error.data[:attribute]
        message = error.message
        model = error.data[:model]
        ActiveModel::Error.full_message(attribute, message, model)
      else
        message = error.message.to_s
        message.empty? ? error.code.to_s : message
      end
    end

  end

end
