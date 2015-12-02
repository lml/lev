module Lev
  module Utils
    module OutputSources
      class VerbatimSubroutines
        def self.setup(routine_class, map)
          map.values.each do |source|
            Uses.setup(routine_class, source)
            promote_verbatim_attributes(routine_class, nil, source)
          end
        end

        private
        def self.promote_verbatim_attributes(routine_class, key, source)
          [source].flatten.each do |src|
            key ||= Symbolify.exec(src)
            nested_class = Nameify.exec(src)

            attrs = nested_class.outputs.select { |k, _| k != :_verbatim }.keys
            routine_class.subroutines[key][:attributes] += attrs

            verbatims = [nested_class.outputs[:_verbatim]].flatten.compact
            promote_verbatim_attributes(routine_class, key, verbatims)
          end
        end
      end
    end
  end
end
