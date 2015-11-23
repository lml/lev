module Lev
  module Utils
    class Outputs
      def self.setup(routine_class, outputs_map)
        routine_class.instance_variable_set('@outputs', outputs_map || {})
        routine_class.define_singleton_method('outputs') { @outputs }

        nested_map = routine_class.outputs.select { |_, source| source != :_self }
        setup_nested_routine_outputs(routine_class.nested_routines, nested_map)
      end

      private
      def self.setup_nested_routine_outputs(nested_routines, map)
        map.each do |attribute, source|
          [source].flatten.each do |src|
            key = Symbolify.exec(src)
            name = Nameify.exec(src)

            nested_routines[key] ||= { routine_class: name, attributes: [] }

            map_attribute(nested_routines, key, attribute)
          end
        end
      end

      def self.map_attribute(nested_routines, key, attribute)
        case attribute
        when :_verbatim
          map_nested_routine_outputs(nested_routines, key)
        else
          nested_routines[key][:attributes] << attribute
        end
      end

      def self.map_nested_routine_outputs(nested_routines, key)
        map = {}

        nested_routines[key][:routine_class].outputs.each do |attr, _|
          map[attr] = Symbolify.exec(nested_routines[key][:routine_class])
        end

        setup_nested_routine_outputs(nested_routines, map)
      end
    end
  end
end
