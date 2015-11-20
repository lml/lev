module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine
            setup_routine_getters(options)
            setup_nested_routine_manifest(options)
          end
        end
      end
    end
  end
end
