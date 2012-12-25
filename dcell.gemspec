# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dcell/version"

Gem::Specification.new do |gem|
  gem.name        = "dcell"
  gem.version     = DCell::VERSION
  gem.authors     = ["Tony Arcieri"]
  gem.email       = ["tony.arcieri@gmail.com"]
  gem.homepage    = "http://github.com/celluloid/dcell"
  gem.summary     = "An asynchronous distributed object framework based on Celluloid"
  gem.description = "DCell is an distributed object framework based on Celluloid built on 0MQ and Zookeeper"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "celluloid",     "~> 0.13.0"
  gem.add_runtime_dependency "celluloid-zmq", "~> 0.13.0"
  gem.add_runtime_dependency "reel"
  gem.add_runtime_dependency "redis"
  gem.add_runtime_dependency "redis-namespace"
  gem.add_runtime_dependency "moneta"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
end
