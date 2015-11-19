module Lev
  module CoreExt
    module Object
      module ClassMethods
        def lev_routine(options = {})
          class_eval do
            include Lev::Routine

            options.each do |key, value|
              instance_variable_set("@#{key}", value)
            end
          end
        end
      end
    end
  end
end
