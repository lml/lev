module Lev
  module Utils
    class Nameify
      def self.exec(source)
        case source
        when Symbol || String
          source.to_s.camelize.constantize
        when Hash
          exec(source[:name])
        else
          source
        end
      end
    end
  end
end
