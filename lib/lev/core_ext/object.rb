require 'lev/utils'

module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine

            Lev::Utils::Options.setup(self, options)
          end
        end

        def lev_handler(options = {})
          class_eval do
            include Lev::Routine

            Lev::Utils::Options.setup(self, options)
          end
        end
      end
    end
  end
end
