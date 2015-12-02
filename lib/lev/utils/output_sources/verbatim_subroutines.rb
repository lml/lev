module Lev
  module Utils
    module OutputSources
      class VerbatimSubroutines
        def self.setup(routine_class, map)
          map.each do |_, source|
            Uses.setup(routine_class, source)

            [source].flatten.each do |src|
              key = Symbolify.exec(src)
              nested_class = Nameify.exec(src)

              attrs = nested_class.outputs.select { |k, _| k != :_verbatim }.keys
              verbatims = [nested_class.outputs[:_verbatim]].flatten.compact

              routine_class.subroutines[key][:attributes] += attrs

              verbatims.each do |verbatim_source|
                verbatim_class = Nameify.exec(verbatim_source)
                attrs = verbatim_class.outputs.select { |k, _| k != :_verbatim }.keys
                verbatims = [verbatim_class.outputs[:_verbatim]].flatten.compact

                routine_class.subroutines[key][:attributes] += attrs
              end
            end
          end
        end
      end
    end
  end
end
