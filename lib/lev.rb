require 'active_record'

require 'lev/core_ext'
require 'lev/configuration'
require 'lev/handle_with'
require 'lev/routine'

module Lev
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  class IllegalArgument < StandardError; end
end
