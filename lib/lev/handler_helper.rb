def handler_errors
  @errors || (@handler_result ? @handler_result.errors : Lev::Errors.new)
end