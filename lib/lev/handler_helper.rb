def handler_errors
  @handler_outcome.try(:errors) || Lev::Errors.new
end