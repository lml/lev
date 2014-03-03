module Lev

  class ErrorTranslator

    def self.translate(error)
      case error.kind
      when :activerecord
        model = error.data[:model]
        attribute = error.data[:attribute]
        # TODO error.message might always be populated now -- really need the other call after ||?
        message = error.message || Lev::BetterActiveModelErrors.generate_message(model, attribute, error.code)
        Lev::BetterActiveModelErrors.full_message(model, attribute, message)
      else
        message = error.message.to_s
        message.empty? ? error.code.to_s : message
      end      
    end

  end

end
