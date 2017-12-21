module Lev
  class Outputs < OpenStruct

    delegate :each_key, to: :to_h

    def initialize(source_hash = nil)
      @array_created = {}
      super
    end

    def add(name, value)
      if self[name].nil?
        self[name] = value
      elsif @array_created[name]
        self[name].push value
      else
        @array_created[name] = true
        self[name] = [self[name], value]
      end
    end

    def each
      each_key do |key|
        key = key.to_sym
        if @array_created[key]
          self[key].each { |value| yield key, value }
        else
          yield key, self[key]
        end
      end
    end

    def transfer_to(other_outputs, &name_mapping_block)
      each do |name, value|
        new_name = block_given? ? name_mapping_block.call(name) : name
        other_outputs.add(new_name, value)
      end
    end

  end
end
