module Lev

  # A collection of Error objects.
  #
  class Errors < Array

    def initialize(routine_status = nil, raise_fatal_errors = false)
      @routine_status = routine_status || NullStatus.new
      @raise_fatal_errors = raise_fatal_errors
    end

    def add(fail, args={})
      args[:kind] ||= :lev
      error = Error.new(args)

      return if ignored_error_procs.any?{|proc| proc.call(error)}
      self.push(error)

      routine_status.add_error(error)

      if fail
        routine_status.failed!

        if raise_fatal_errors
          # Use special FatalError type so Routine doesn't re-add status errors
          raise Lev::FatalError, args.to_a.map { |i| i.join(' ') }.join(' - ')
        else
          throw :fatal_errors_encountered
        end
      end
    end

    def ignore(arg)
      proc = arg.is_a?(Symbol) ?
               Proc.new{|error| error.code == arg} :
               arg

      raise Lev.configuration.illegal_argument_error if !proc.respond_to?(:call)

      ignored_error_procs.push(proc)
    end

    def [](key)
      self[key]
    end

    # Checks to see if the provided input is associated with one of the errors.
    def has_offending_input?(input)
      self.any? {|error| [error.offending_inputs].flatten.include? input}
    end

    def raise_exception_if_any!(exception_type = StandardError)
      raise exception_type, collect{|error| error.message}.join('; ') if any?
    end

  protected

    attr_reader :routine_status
    attr_reader :raise_fatal_errors

    def ignored_error_procs
      @ignored_error_procs ||= []
    end

  end
end
