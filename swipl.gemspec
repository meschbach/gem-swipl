# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swipl/version'

Gem::Specification.new do |spec|
  spec.name          = "swipl"
  spec.version       = SWIPL::VERSION
  spec.authors       = ["Mark Eschbach"]
  spec.email         = ["meschbach@gmail.com"]

  spec.summary       = %q{Ruby bindings for SWI Prolog}
  spec.description   = %q{Interact with the SWI Prolog system in ruby.  Currently uses FFI to bind using the C interface.}
  spec.homepage      = "https://github.com/meschbach/gem-swipl"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_dependency "ffi", "~> 1.9"
end
