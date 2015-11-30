module Lev
  module Utils
    class NestedRoutines
      def self.setup(routine_class, intended_nested_routines)
        [intended_nested_routines].flatten.each do |src|
          key = Symbolify.exec(src)
          name = Nameify.exec(src)
          name_alias = Aliasify.exec(src)

          routine_class.nested_routines[key] ||= { name_alias: name_alias,
                                                   routine_class: name,
                                                   attributes: Set.new }
        end
      end
    end
  end
end
