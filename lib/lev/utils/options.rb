module Lev
  module Utils
    class Options
      def self.setup(routine_class, options)
        options = { outputs: {}, uses: [] }.merge(options)

        ReadableAttrs.setup(routine_class, options)
        Outputs.setup(routine_class, options[:outputs])
        routine_class.subroutines.add(options[:uses])
      end
    end
  end
end
