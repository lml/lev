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

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency(%q<activemodel>, [">= 3.0"])
  spec.add_runtime_dependency(%q<activerecord>, [">= 3.0"])
  spec.add_runtime_dependency(%q<actionpack>, [">= 3.0"])
  spec.add_runtime_dependency "transaction_isolation"
  spec.add_runtime_dependency "transaction_retry"
  spec.add_runtime_dependency "active_attr"
  spec.add_runtime_dependency "hashie"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "debugger"

end
