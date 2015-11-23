module Lev
  module Utils
    class Symbolify
      def self.exec(source)
        case source
        when Class || Module
          source.name.underscore.gsub('/', '_').to_sym
        when String
          source.to_sym
        when Hash
          exec(source[:as] || source[:name])
        else
          source
        end
      end
    end
  end
end
