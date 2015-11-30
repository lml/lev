module Lev
  module Utils
    class Subroutines
      def self.setup(routine_class, options)
        used_routines = [options[:uses]].flatten.compact
        nested_map = (options[:outputs] || {}).select { |_, source| source != :_self }

        setup_subroutines(routine_class, used_routines)
        setup_subroutine_outputs(routine_class, nested_map)
      end

      private
      def self.setup_subroutines(routine_class, routines)
        [routines].flatten.each do |src|
          key = Symbolify.exec(src)
          name = Nameify.exec(src)
          name_alias = Aliasify.exec(src)

          routine_class.subroutines[key] ||= { name_alias: name_alias,
                                               routine_class: name,
                                               attributes: Set.new }
        end
      end

      def self.setup_subroutine_outputs(routine_class, map)
        map.each do |attribute, source|
          setup_subroutines(routine_class, source)

          [source].flatten.each do |src|
            key = Symbolify.exec(src)
            map_attribute(routine_class, key, attribute)
          end
        end
      end

      def self.map_attribute(routine_class, key, attribute)
        case attribute
        when :_verbatim
          promote_verbatim_attributes(routine_class, key)
        else
          routine_class.subroutines[key][:attributes] << attribute
        end
      end

      # TODO: This is so bad
      # blame joemsak
      def self.promote_verbatim_attributes(routine_class, key)
        nested_class = routine_class.subroutines[key][:routine_class]
        map = nested_class.outputs
        sub_map = {}

        map.each do |attr, source|
          construct_map(map, attr, source, sub_map, nested_class)
        end

        setup_subroutine_outputs(routine_class, map.merge(sub_map))
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
          nested_class.subroutines[key][:attributes].each do |attr|
            sub_map[attr] = nested_class
          end
        end
      end
    end
  end
end
