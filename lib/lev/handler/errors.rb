class Lev::Handler::Errors < Array
  def add(args)
    push(Lev::Handler::Error.new(args))
  end

  def [](key)
    self[key]
  end

  # Checks to see if the provided param identifier is one of the offending
  # params, e.g. has_offending_param?([:my_form, :my_text_field_name])
  def has_offending_param?(param)
    self.any?{|error| error.offending_params.any?{|e| param == e}}
  end
end
