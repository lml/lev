module Lev
  module Utils
    class Options
      def self.setup(routine_class, options)
        options = { outputs: {}, uses: [] }.merge(options)

        routine_class.setup_readable_attrs(options)
        Outputs.setup(routine_class, options[:outputs])
        routine_class.subroutines.add(options[:uses])
      end
    end
  end
end
