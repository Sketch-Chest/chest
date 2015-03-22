# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chest/version'

Gem::Specification.new do |spec|
  spec.name          = 'chest'
  spec.version       = Chest::VERSION
  spec.authors       = ['Yasuaki Uechi']
  spec.email         = ['uetchy@randompaper.co']

  spec.summary       = %q{The lightweight plugin manager for Sketch.app}
  spec.homepage      = 'https://github.com/uetchy/Sketch-Chest'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'thor'
  spec.add_dependency 'rest-client'
  spec.add_dependency 'rubyzip'
  spec.add_dependency 'semantic'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry-byebug'
end
