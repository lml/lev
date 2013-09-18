
module Lev

  # A utility method for calling handlers from controllers.  To use,
  # include this in your relevant controllers (or in your ApplicationController),
  # e.g.:
  #
  #   class ApplicationController
  #     include Lev::HandleWith
  #     ...
  #   end
  #
  # Then, call it from your various controller actions, e.g.:
  #
  #   handle_with(MyFormHandler,
  #               params: params,
  #               success: lambda { redirect_to 'show', notice: 'Success!'},
  #               failure: lambda { render 'new', alert: 'Error' })
  #
  # handle_with takes care of calling the handler and populates
  # @errors and @results objects with the return values from the handler
  #
  # The 'success' and 'failure' lambdas are called if there aren't or are errors,
  # respectively.  Alternatively, if you supply a 'complete' lambda, that lambda
  # will be called regardless of whether there are any errors.
  #
  # Specifying 'params' is optional.  If you don't specify it, HandleWith will
  # use the entire params hash from the request.
  #
  module HandleWith
    def handle_with(handler, options)
      success_action = options.delete(:success) || lambda {}
      failure_action = options.delete(:failure) || lambda {}
      complete_action = options.delete(:complete) || lambda {}

      options[:params]  ||= params
      options[:request] ||= request
      options[:caller] ||= current_user

      @results, @errors = handler.handle(options)

      if complete_action.nil?
        @errors.empty? ?
          success_action.call :
          failure_action.call    
      else
        complete_action.call
      end
    end
  end

end
