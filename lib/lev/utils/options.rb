module Lev
  module Utils
    class Options
      def self.setup(routine_class, options)
        outputs = options.delete(:outputs) || {}
        subroutines = options.delete(:uses) || []

        routine_class.setup_readable_attrs(options)
        routine_class.outputs.add(outputs)
        routine_class.subroutines.add(subroutines)
      end
    end
  end
end
