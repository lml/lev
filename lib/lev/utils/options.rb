module Lev
  module Utils
    class Options
      def self.setup(routine_class, options)
        Manifest.setup(routine_class, options.delete(:manifest))
        setup_routine_getters(routine_class, options)
      end

      private
      def self.setup_routine_getters(routine_class, map)
        map.each do |key, value|
          routine_class.instance_variable_set("@#{key}", value)

          routine_class.define_singleton_method(key) do
            instance_variable_get("@#{key}")
          end
        end
      end
    end
  end
end
