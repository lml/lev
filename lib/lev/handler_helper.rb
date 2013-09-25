def handler_errors
  @errors || (@handler_outcome ? @handler_outcome.errors : Lev::Errors.new)
end