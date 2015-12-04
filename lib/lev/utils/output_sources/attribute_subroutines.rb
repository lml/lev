module Lev
  module Utils
    module OutputSources
      class AttributeSubroutines
        def self.setup(routine_class, map)
          map.each do |attr, source|
            key = Symbolify.exec(source)

            routine_class.subroutines.add(source)
            routine_class.subroutines.add_attribute(key, attr)
          end
        end
      end
    end
  end
end
