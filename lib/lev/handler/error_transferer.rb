class Lev::Handler::ErrorTransferer

  def self.transfer(source, handler_target, param_group)
    case source
    when ActiveRecord::Base
      source.errors.each_type do |attribute, type|
        handler_target.errors.add(
          code: type, 
          data: source, 
          kind: :activerecord,
          offending_params: [param_group].flatten << attribute
        )
      end
    else
      raise Exception
    end

  end


end