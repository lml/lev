module Lev
  module Utils
    class NestedRoutines
      def self.setup(routine_class, intended_nested_routines)
        [intended_nested_routines].flatten.compact.each do |nested_routine|
          key = Symbolify.exec(nested_routine)
          name = Nameify.exec(nested_routine)

          routine_class.nested_routines[key] ||= { routine_class: name, attributes: [] }
        end
      end
    end
  end
end
