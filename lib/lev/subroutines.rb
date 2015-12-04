module Lev
  class Subroutines < Hash
    def add(source)
      key = Utils::Symbolify.exec(source)
      name = Utils::Nameify.exec(source)
      name_alias = Utils::Aliasify.exec(source)

      self[key] ||= { name_alias: name_alias,
                      routine_class: name,
                      attributes: Set.new }
    end

    def attributes(name)
      find(name)[:attributes]
    end

    def add_attribute(key, attr)
      find(key)[:attributes] << attr
    end

    def routine_class(name)
      find(name)[:routine_class]
    end

    def find(name)
      name = Utils::Symbolify.exec(name)
      select { |k, opts| k == name || opts[:name_alias] == name }.values.first
    end
  end
end
