module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine

            setup_manifest(options.delete(:manifest))
            setup_routine_getters(options)

            nested_map = manifest.select { |_, source| source != :_self }
            setup_nested_routine_manifest(nested_map)
          end
        end
      end
    end
  end
end
