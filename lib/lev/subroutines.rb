module Lev
  class Subroutines < Hash
    def add(source)
      [source].flatten.compact.each do |src|
        key = Utils::Symbolify.exec(src)
        name = Utils::Nameify.exec(src)
        name_alias = Utils::Aliasify.exec(src)

        self[key] ||= { name_alias: name_alias,
                        routine_class: name,
                        attributes: Set.new }
      end
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
