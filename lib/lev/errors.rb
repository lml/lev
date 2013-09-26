module Lev

  # A collection of Error objects.  Mostly a glorified Array.
  #
  class Errors < Array
    def add(args)
      push(Error.new(args))
    end

    def [](key)
      self[key]
    end

    # Checks to see if the provided input is associated with one of the errors.
    def has_offending_input?(input)
      self.any? {|error| error.offending_inputs.include? input}
    end
  end
end