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
          map_attribute(routine_class, source, attribute)
        end
      end

      def self.map_attribute(routine_class, source, attribute)
        [source].flatten.each do |src|
          key = Symbolify.exec(src)

          case attribute
          when :_verbatim
            promote_verbatim_attributes(routine_class, key)
          else
            routine_class.subroutines[key][:attributes] << attribute
          end
        end
      end

      def self.promote_verbatim_attributes(routine_class, key)
        subroutine = routine_class.subroutines[key]
        nested_class = subroutine[:routine_class]
        sub_attrs = nested_class.subroutines.values.collect { |v| v[:attributes] }.first
        map = {}

        nested_class.outputs.each do |attr, _|
          case attr
          when :_verbatim
            sub_attrs.each { |attr| map[attr] = nested_class }
          else
            map[attr] = nested_class
          end
        end

        #binding.pry if routine_class.name == 'UseTheNameSpaced'

        setup(routine_class, { outputs: map })
      end
    end
  end
end
