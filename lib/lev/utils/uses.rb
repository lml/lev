module Lev
  module Utils
    class Uses
      def self.setup(routine_class, used_routines)
        [used_routines].flatten.compact.each do |src|
          key = Symbolify.exec(src)
          name = Nameify.exec(src)
          name_alias = Aliasify.exec(src)

          routine_class.subroutines[key] ||= { name_alias: name_alias,
                                               routine_class: name,
                                               attributes: Set.new }
        end
      end
    end
  end
end
