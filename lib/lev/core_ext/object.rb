module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine

            @raise_fatal_errors = options[:raise_fatal_errors]
          end
        end
      end
    end
  end
end
