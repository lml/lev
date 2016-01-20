class Lev::NullStatus
  attr_reader :id

  def initialize(id=nil)
    @id = id || "null-status:#{SecureRandom.uuid}"
    @kill_requested = false
  end

  def request_kill!
    @kill_requested = true
  end

  def kill_requested?
    @kill_requested
  end

  def method_missing(*args, &block)
    nil
  end

  # Provide null object pattern methods for status setter methods called from
  # within routines; routines should not be using other query methods to check
  # their own status (they should know it), with the exception of `kill_requested?`

  def set_progress(*); end
  def save(*); end
  def add_error(*); end

  def queued!; end
  def started!; end
  def succeeded!; end
  def failed!; end
  def killed!; end
end
