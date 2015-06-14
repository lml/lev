module Lev
  class BlackHoleStatus

    # Provide null object pattern methods for status setters; routines should
    # not be checking their own status (they should know it), and outside callers
    # should not be checking status unless the status object is a real one.

    def set_progress(*); end
    def save(*); end
    def add_error(*); end

    def self.method_missing(method_sym, *args, &block)
      if Lev::Status.new.respond_to?(method_sym)
        raise NameError,
              "'#{method_sym}' is Status query method, and those cannot be called on BlackHoleStatus"
      else
        super
      end
    end

  end
end
