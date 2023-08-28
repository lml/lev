# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lev/version'

Gem::Specification.new do |spec|
  spec.name          = "lev"
  spec.version       = Lev::VERSION
  spec.authors       = ["JP Slavinsky"]
  spec.email         = ["jps@kindlinglabs.com"]
  spec.description   = %q{Ride the rails but don't touch them.}
  spec.summary       = %q{Ride the rails but don't touch them.}
  spec.homepage      = "http://github.com/lml/lev"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + ['LICENSE.txt', 'Rakefile', 'README.md']
  spec.test_files    = Dir["spec/**/*"]

  spec.add_runtime_dependency "activemodel", ">= 6.1"
  spec.add_runtime_dependency "activerecord", ">= 4.2"
  spec.add_runtime_dependency "actionpack", ">= 4.2"
  spec.add_runtime_dependency "activejob"
  spec.add_runtime_dependency "transaction_isolation"
  spec.add_runtime_dependency "openstax_transaction_retry"
  spec.add_runtime_dependency "active_attr"
  spec.add_runtime_dependency "hashie"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "jobba", ">= 1.5"
end
