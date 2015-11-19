require 'lev/core_ext/object'
require 'lev/core_ext/active_job'

module Lev
  module CoreExt
  end
end

Object.extend Lev::CoreExt::Object::ClassMethods
