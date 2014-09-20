# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roda/plugins/version'

Gem::Specification.new do |spec|
  spec.name          = "roda-plugins"
  spec.version       = Roda::PluginsVersion
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.summary       = %q{Plugins for Roda.}
  spec.description   = %q{Plugins for Roda}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "roda"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "minitest", "~> 5.4.1"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "rake", '~> 10.3'
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "sass"
  spec.add_development_dependency "coffee-script"
  spec.add_development_dependency "tilt"
end
