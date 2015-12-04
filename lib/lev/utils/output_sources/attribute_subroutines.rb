module Lev
  module Utils
    module OutputSources
      class AttributeSubroutines
        def self.setup(routine_class, map)
          map.each do |attr, source|
            key = Symbolify.exec(source)

            routine_class.add_subroutines(source)
            routine_class.add_attribute(key, attr)
          end
        end
      end
    end
  end
end
