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
            name_alias = Aliasify.exec(src)

            nested_routines[key] ||= { name_alias: name_alias,
                                       routine_class: name,
                                       attributes: Set.new }

            map_attribute(nested_routines, key, attribute)
          end
        end
      end

      def self.map_attribute(nested_routines, key, attribute)
        case attribute
        when :_verbatim
          promote_verbatim_attributes(nested_routines, key)
        else
          nested_routines[key][:attributes] << attribute
        end
      end

      # TODO: This is so bad
      # blame joemsak
      def self.promote_verbatim_attributes(nested_routines, key)
        nested_class = nested_routines[key][:routine_class]
        map = nested_class.outputs
        sub_map = {}

        map.each do |attr, source|
          construct_map(map, attr, source, sub_map, nested_class)
        end

        setup_nested_routine_outputs(nested_routines, map.merge(sub_map))
      end

      def self.construct_map(map, attr, source, sub_map, nested_class)
        case attr
        when :_verbatim
          construct_sub_map(nested_class, source, sub_map)
          map.delete(:_verbatim)
        else
          map[attr] = nested_class
        end
      end

      def self.construct_sub_map(nested_class, source, sub_map)
        [source].flatten.each do |src|
          key = Symbolify.exec(src)
          nested_class.nested_routines[key][:attributes].each do |attr|
            sub_map[attr] = nested_class
          end
        end
      end
    end
  end
end
