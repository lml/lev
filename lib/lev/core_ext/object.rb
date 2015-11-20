module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine

            options.each do |key, value|
              instance_variable_set("@#{key}", value)

              define_singleton_method(key) do
                instance_variable_get("@#{key}")
              end
            end

            manifest = options[:manifest] || {}
            nested_routine_map = manifest.select { |_, source| source != :_self }
            setup_nested_routine_manifest(nested_routine_map)
          end
        end
      end
    end
  end
end
