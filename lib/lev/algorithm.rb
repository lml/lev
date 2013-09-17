module Lev
  #   http://ducktypo.blogspot.com/2010/08/why-inheritance-sucks.html
  #   http://stackoverflow.com/a/1328093/1664216
  module Algorithm

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        include Lev::RoutineNesting
      end
    end

    def call(*args, &block)
      in_transaction do
        exec(*args, &block)
      end
    end

    module ClassMethods
      def call(*args, &block)
        new.call(*args, &block)
      end
    end

  end
end