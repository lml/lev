require 'lev/utils/output_sources'

module Lev
  module Utils
    class Outputs
      def self.setup(routine_class, outputs)
        subroutine_sources = outputs.select { |_, v| v != :_self }
        OutputSources::Subroutines.setup(routine_class, subroutine_sources)
      end
    end
  end
end
