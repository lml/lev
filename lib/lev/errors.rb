module Lev

  # A collection of Error objects.  
  #
  class Errors < Array

    def add(fail, args={}) 
      args[:kind] ||= :lev
      error = Error.new(args)
      return if ignored_error_procs.any?{|proc| proc.call(error)}
      self.push(error)
      throw :fatal_errors_encountered if fail
    end

    def ignore(arg)
      proc = arg.is_a?(Symbol) ?
               Proc.new{|error| error.code == arg} :
               arg
      
      raise IllegalArgument if !proc.respond_to?(:call)

      ignored_error_procs.push(proc)
    end

    def [](key)
      self[key]
    end

    # Checks to see if the provided input is associated with one of the errors.
    def has_offending_input?(input)
      self.any? {|error| [error.offending_inputs].flatten.include? input}
    end

  protected

    def ignored_error_procs
      @ignored_error_procs ||= []
    end

  end
end