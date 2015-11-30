module Lev
  module Utils
    class Subroutines
      def self.setup(routine_class, intended_subroutines)
        [intended_subroutines].flatten.compact.each do |src|
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
