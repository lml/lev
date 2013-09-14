module Lev::Handler

  class ErrorTransferer

    def self.transfer(source, handler_target, param_group)
      case source
      when ActiveRecord::Base, Lev::Paramifier
        source.errors.each_with_type_and_message do |attribute, type, message|
          handler_target.errors.add(
            code: type, 
            data: {
              model: source,
              attribute: attribute
            }, 
            kind: :activerecord,
            message: message,
            offending_params: [param_group].flatten << attribute
          )
        end
      else
        raise Exception
      end

    end

  end

end