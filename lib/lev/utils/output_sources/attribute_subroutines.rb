module Lev
  module Utils
    module OutputSources
      class AttributeSubroutines
        def self.setup(routine_class, map)
          map.each do |attr, source|
            key = Symbolify.exec(source)

            Uses.setup(routine_class, source)
            routine_class.subroutines[key][:attributes] << attr
          end
        end
      end
    end
  end
end
