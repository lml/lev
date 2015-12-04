require 'lev/utils/output_sources'

module Lev
  module Utils
    class Outputs
      def self.setup(routine_class, outputs)
        subroutine_srcs = outputs.select { |_, v| v != :_self }

        attr_subroutine_srcs = subroutine_srcs.select { |k, _| k != :_verbatim }
        OutputSources::AttributeSubroutines.setup(routine_class, attr_subroutine_srcs)

        verbatim_subroutine_srcs = subroutine_srcs.select { |k, _| k == :_verbatim }
        OutputSources::VerbatimSubroutines.setup(routine_class, verbatim_subroutine_srcs)
      end
    end
  end
end
