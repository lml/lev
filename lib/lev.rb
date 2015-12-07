require 'active_record'
require 'active_attr'

require 'lev/core_ext'
require 'lev/configuration'

require 'lev/routine'
require 'lev/handle_with'
require 'lev/handler'

module Lev
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end

  class IllegalArgument < StandardError; end
end
