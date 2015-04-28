# -*- encoding: utf-8 -*-

require_relative "lib/dcell/version"

Gem::Specification.new do |gem|
  gem.name        = "dcell"
  gem.version     = DCell::VERSION
  gem.license     = 'MIT'
  gem.authors     = ["Tony Arcieri"]
  gem.email       = ["tony.arcieri@gmail.com"]
  gem.homepage    = "http://github.com/celluloid/dcell"
  gem.summary     = "An asynchronous distributed object framework based on Celluloid"
  gem.description = "DCell is an distributed object framework based on Celluloid built on 0MQ and Zookeeper"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "celluloid",       "~> 0.16.0"
  gem.add_runtime_dependency "celluloid-zmq",   "~> 0.16.1"

  gem.add_runtime_dependency "reel",            "~> 0.4.0"
  gem.add_runtime_dependency "http",            "~> 0.5.0"
  gem.add_runtime_dependency "msgpack",         "~> 0.5"
  gem.add_runtime_dependency "celluloid-redis", "~> 0.0.2"
  gem.add_runtime_dependency "redis-namespace", "~> 1.5"
  gem.add_runtime_dependency "facter",          "~> 2.4"

  gem.add_development_dependency "rake",        "~> 10.4"
  gem.add_development_dependency "rspec",       "~> 3.0"
end
