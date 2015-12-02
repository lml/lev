module Lev
  module Utils
    class ReadableAttrs
      def self.setup(routine_class, options)
        options.each do |key, value|
          routine_class.instance_variable_set("@#{key}", value)

          routine_class.define_singleton_method(key) do
            instance_variable_get("@#{key}")
          end
        end
      end
    end
  end
end
