module Lev
  module Handler
    def self.included(base)
      base.extend ClassMethods
    end

    def initialize(options = {})
    end

    def call(options = {})
      @params = options.delete(:params) || {}
      handle
      result
    end

    module ClassMethods
      def call(options = {}); new.call(options); end

      def paramify(root, &block)
        paramifiers[root] ||= Class.new(Paramifier)
        paramifiers[root].class_eval(&block)

        define_method "#{root}_params" do
          if !instance_variable_get("@#{root}_params")
            instance_variable_set("@#{root}_params",
                                  self.class.paramifiers[root].new(params[root]))
          end

          instance_variable_get("@#{root}_params")
        end
      end

      def paramifiers
        @paramifiers ||= {}
      end
    end

    private
    attr_accessor :params

    class Paramifier
      include ActiveAttr::Model
      include ActiveAttr::Typecasting

      # Hack to provide ActiveAttr's Boolean type concisely
      def self.boolean; ActiveAttr::Typecasting::Boolean; end
    end
  end
end
