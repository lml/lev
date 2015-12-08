module Lev
  module Query
    def self.included(base)
      base.extend ClassMethods
    end

    def call(*args, &block)
      query(*args, &block)
    end

    module ClassMethods
      def promote_mapped_attributes(routine, sub_result)
        routine.class.subroutines.attributes(self).each do |attr|
          routine.set(attr => sub_result)
        end
      end
    end
  end
end
