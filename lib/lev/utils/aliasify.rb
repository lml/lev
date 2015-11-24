module Lev
  module Utils
    class Aliasify
      def self.exec(source)
        case source
        when Hash
          Symbolify.exec(source[:as] || source[:name])
        else
          Symbolify.exec(source)
        end
      end
    end
  end
end
