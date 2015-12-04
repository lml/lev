module Lev
  module Utils
    class Outputs
      def self.setup(routine_class, outputs)
        subroutine_srcs = outputs.select { |_, v| v != :_self }

        subroutine_srcs.select { |k, _| k != :_verbatim }.each do |attr, source|
          add_attribute_subroutines(routine_class, source, attr)
        end

        subroutine_srcs.select { |k, _| k == :_verbatim }.values.each do |source|
          add_verbatim_subroutines(routine_class, source)
        end
      end

      private
      def self.add_attribute_subroutines(routine_class, source, attr)
        key = Symbolify.exec(source)

        routine_class.subroutines.add(source)
        routine_class.subroutines.add_attribute(key, attr)
      end

      def self.add_verbatim_subroutines(routine_class, source)
        routine_class.subroutines.add(source)
        promote_verbatim_attributes(routine_class, nil, source)
      end

      def self.promote_verbatim_attributes(routine_class, key, source)
        [source].flatten.each do |src|
          key ||= Symbolify.exec(src)

          nested_class = Nameify.exec(src)
          source_class = routine_class.subroutines.routine_class(key)

          nested_class.explicit_outputs.each do |attr|
            routine_class.subroutines.add_attribute(key, attr)
          end

          promote_verbatim_attributes(routine_class, key, nested_class.verbatim_outputs)
        end
      end
    end
  end
end
