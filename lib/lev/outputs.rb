module Lev
  class Outputs < Hash
    def initialize(routine, map)
      @routine = routine
      super(map)
    end

    def add(map)
      map.each { |k, v| self[k] = v }
      add_attribute_subroutines
      add_verbatim_subroutines
    end

    def explicit
      select { |k, _| k != :_verbatim }
    end

    def explicit_external
      select { |k, v| k != :_verbatim && v != :_self }
    end

    def verbatim
      [self[:_verbatim]].flatten.compact
    end

    private
    attr_reader :routine

    def add_attribute_subroutines
      explicit_external.each do |attr, source|
        routine.subroutines.add(source)
        routine.subroutines.add_attribute(source, attr)
      end
    end

    def add_verbatim_subroutines
      verbatim.each do |source|
        routine.subroutines.add(source)
        promote_verbatim_attributes(source, nil)
      end
    end

    def promote_verbatim_attributes(source, key)
      [source].flatten.each do |src|
        key ||= Utils::Symbolify.exec(src)

        nested_class = Utils::Nameify.exec(src)
        source_class = routine.subroutines.routine_class(key)

        next if nested_class.nil?

        nested_class.outputs.explicit.each do |attr, _|
          routine.subroutines.add_attribute(key, attr)
        end

        promote_verbatim_attributes(nested_class.outputs.verbatim, key)
      end
    end
  end
end
