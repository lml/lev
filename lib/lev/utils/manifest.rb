module Lev
  module Utils
    class Manifest
      def self.setup(routine_class, manifest_map)
        routine_class.instance_variable_set('@manifest', manifest_map || {})
        routine_class.define_singleton_method('manifest') { @manifest }

        nested_map = routine_class.manifest.select { |_, source| source != :_self }
        setup_nested_routine_manifest(routine_class.nested_routines, nested_map)
      end

      private
      def self.setup_nested_routine_manifest(nested_routines, map)
        map.each do |attribute, source|
          nested_routines[source] ||= {
            routine_class: source.to_s.classify.constantize,
            attributes: []
          }

          map_attribute(nested_routines, source, attribute)
        end
      end

      def self.map_attribute(nested_routines, source, attribute)
        case attribute
        when :_verbatim
          map_nested_routine_manifest(nested_routines, source)
        else
          nested_routines[source][:attributes] << attribute
        end
      end

      def self.map_nested_routine_manifest(nested_routines, source)
        map = {}

        nested_routines[source][:routine_class].manifest.each do |attr, _|
          map[attr] = nested_routines[source][:routine_class].name.underscore.to_sym
        end

        setup_nested_routine_manifest(nested_routines, map)
      end
    end
  end
end
