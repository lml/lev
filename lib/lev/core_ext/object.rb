require 'lev/utils'

module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine

            Lev::Utils::Manifest.setup(self, options.delete(:manifest))
            setup_routine_getters(options)
          end
        end
      end
    end
  end
end
