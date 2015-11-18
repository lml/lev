require 'lev/core_ext'
require 'lev/configuration'
require 'lev/routine'

module Lev
  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield configuration
  end
end
