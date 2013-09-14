
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
      options[:success] ||= lambda {}
      options[:failure] ||= lambda {}
      options[:params] ||= params

      @results, @errors = handler.handle(current_user, options[:params])

      if options[:complete].nil?
        @errors.empty? ?
          options[:success].call :
          options[:failure].call    
      else
        options[:complete].call
      end
    end
  end

end
