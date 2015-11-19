module Lev
  class NoBackgroundJob
    # Provide null object pattern methods for background jobs; routines should
    # not be checking their own status (they should know it), and outside callers
    # should not be checking status unless the background job is a real one.

    def set_progress(*); end
    def save(*); end

    Lev::BackgroundJob::STATES.each do |state|
      define_method("#{state}!") do |*|; end
    end

    def self.method_missing(method_sym, *args, &block)
      if Lev::BackgroundJob.method_defined?(method_sym)
        raise NameError, "Unsupported method '##{method_sym}' called on NoBackgroundJob"
      else
        super
      end
    end
  end
end
