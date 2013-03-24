# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruote/resque/version'

Gem::Specification.new do |gem|
  gem.name          = "ruote-resque"
  gem.version       = Ruote::Resque::VERSION
  gem.authors       = ["Adrien Kohlbecker"]
  gem.email         = ["adrien.kohlbecker@gmail.com"]
  gem.description   = %q{Resque participant/receiver pair for Ruote}
  gem.summary       = %q{Resque participant/receiver pair for Ruote}
  gem.homepage      = "https://github.com/adrienkohlbecker/ruote-resque"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'resque'
  gem.add_runtime_dependency 'ruote'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
end
