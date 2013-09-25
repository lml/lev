module Lev
  class Errors < Array
    def add(args)
      push(Error.new(args))
    end

    def [](key)
      self[key]
    end

    # # Checks to see if the provided address identifier is recorded in an error, 
    # # e.g. has_address?([:my_form, :my_text_field_name])
    # def has_address?(address)
    #   self.any?{|error| error.address == address}
    # end

    def has_offending_input?(input)
      self.any? {|error| error.offending_inputs.include? input}
    end
  end
end