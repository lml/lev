module Lev
  module Utils
    module OutputSources
      class VerbatimSubroutines
        def self.setup(routine_class, map)
          map.values.each do |source|
            routine_class.add_subroutines(source)
            promote_verbatim_attributes(routine_class, nil, source)
          end
        end

        private
        def self.promote_verbatim_attributes(routine_class, key, source)
          [source].flatten.each do |src|
            key ||= Symbolify.exec(src)

            nested_class = Nameify.exec(src)
            source_class = routine_class.subroutine_class(key)

            nested_class.explicit_outputs.each do |attr|
              AttributeSubroutines.setup(routine_class, { attr => source_class })
            end

            promote_verbatim_attributes(routine_class, key, nested_class.verbatim_outputs)
          end
        end
      end
    end
  end
end
