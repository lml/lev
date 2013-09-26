module Lev

  class ErrorTransferer

    def self.transfer(source, target_routine, input_mapper, fail_if_errors=false)
      case source
      when ActiveRecord::Base, Lev::Paramifier
        source.errors.each_with_type_and_message do |attribute, type, message|
          target_routine.nonfatal_error(
            code: type, 
            data: {
              model: source,
              attribute: attribute
            }, 
            kind: :activerecord,
            message: message,
            offending_inputs: input_mapper.map(attribute)
          )
        end
      when Lev::Errors
        source.each do |error|
          target_routine.nonfatal_error(
            code: error.code,
            data: error.data,
            kind: error.kind,
            message: error.message,
            offending_inputs: input_mapper.map(error.offending_inputs)
          )
        end
      else
        raise Exception
      end

      # We add nonfatal errors above and then have this call here so that all
      # errors can be transferred before we freak out.
      throw :fatal_errors_encountered if target_routine.errors? && fail_if_errors
    end

  end

end