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

            nested_routines[key] ||= { routine_class: name, attributes: Set.new }

            map_attribute(nested_routines, key, attribute)
          end
        end
      end

      def self.map_attribute(nested_routines, key, attribute)
        case attribute
        when :_verbatim
          ## HERE IT IS IN WIP
          #
          # Trying to promote the nested routine's nested attributes up to
          # the parent routine's attributes
          #
          # basically, all verbatim attributes in a given nested routine
          # become attributes on THAT nested routine for the parent routine
          #
          # shitty loop logic, i know. hard to follow
          #
          # my plan was to get it working and then of course
          # clean it up and section it off in distinct functions
          nested_class = nested_routines[key][:routine_class]
          map = nested_class.outputs
          sub_map = {}

          map.each do |attr, source|
            case attr
            when :_verbatim
              [source].flatten.each do
                key = Symbolify.exec(source)
                nested_class.nested_routines[key][:attributes].each do |attr|
                  sub_map[attr] = source
                end
              end
            else
              map[attr] = nested_class
            end
          end

          map.merge!(sub_map)

          setup_nested_routine_outputs(nested_routines, map)
        else
          nested_routines[key][:attributes] << attribute
        end
      end
    end
  end
end
