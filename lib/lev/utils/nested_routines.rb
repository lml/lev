module Lev
  module Utils
    class NestedRoutines
      def self.setup(routine_class, intended_nested_routines)
        [intended_nested_routines].flatten.compact.each do |nested_routine|
          routine_class.nested_routines[nested_routine] ||= {
            routine_class: nested_routine.to_s.classify.constantize,
            attributes: []
          }
        end
      end
    end
  end
end
