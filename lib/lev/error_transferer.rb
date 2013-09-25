module Lev

  class ErrorTransferer

    def self.transfer(source, target_routine, input_mapper=InputMapper.new)
      case source
      when ActiveRecord::Base, Lev::Paramifier
        source.errors.each_with_type_and_message do |attribute, type, message|
          debugger
          target_routine.errors.add(
            code: type, 
            data: {
              model: source,
              attribute: attribute
            }, 
            kind: :activerecord,
            message: message,
            # address: [scope, attribute].flatten.compact,
            offending_inputs: input_mapper.map(attribute)
          )
        end
      when Lev::Errors
        source.each do |error|
          target_routine.errors.add(
            code: error.code,
            data: error.data,
            kind: error.kind,
            message: error.message,
            # address: [scope, error.address].flatten.compact,
            offending_inputs: input_mapper.map(error.offending_inputs)
          )
        end
      else
        raise Exception
      end

    end

  end

end