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

    # # Adds error code to the list of ignored errors (making raise_error not do
    # # anything for that code), and returns self so calls can be chained
    # def ignore_error(code)
    #   ignored_errors.push(code)
    #   self
    # end

    attr_accessor :errors

  protected
    
    attr_accessor :results

    def fail_if_errors!
      throw :fail_if_errors if errors.any?
    end

    # def ignored_errors
    #   @ignored_errors ||= []
    # end

    # # Raises an exception where the message is an array of symbols that target
    # # the raised error code, e.g. if ModuleA::Algorithm4 raises a :foo error code
    # # the exception's message will be [:module_a, :algorithm4, :foo].  This code
    # # can then be used in locale translations (TBD).
    # def raise_error(code, options={})
    #   return if ignored_errors.include?(code)
    #   full_code = self.class.name.underscore.split("/").collect{|part| part.to_sym}.push(code)
    #   raise (options[:exception] || Lev::AlgorithmError), full_code
    # end

  end
end