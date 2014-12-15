# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dcell/version"

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

  gem.add_runtime_dependency "celluloid",     "~> 0.16.0"
  gem.add_runtime_dependency "celluloid-zmq", "~> 0.16.0"
  gem.add_runtime_dependency "reel",          "~> 0.4.0"
  gem.add_runtime_dependency "http",          "~> 0.5.0"
  if RUBY_PLATFORM == 'java'
    gem.add_runtime_dependency "msgpack-jruby"
  else
    gem.add_runtime_dependency "msgpack"
  end
  gem.add_runtime_dependency "celluloid-redis"
  gem.add_runtime_dependency "redis-namespace"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec",     "~> 2.14.0"
end
