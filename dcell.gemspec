# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "dcell/version"

Gem::Specification.new do |s|
  s.name        = "dcell"
  s.version     = DCell::VERSION
  s.authors     = ["Tony Arcieri"]
  s.email       = ["tony.arcieri@gmail.com"]
  s.homepage    = "http://github.com/tarcieri/dcell"
  s.summary     = "An asynchronous distributed object framework based on Celluloid"
  s.description = "DCell is an distributed object framework based on Celluloid built on 0MQ and Zookeeper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "celluloid", ">= 0.6.2"
  s.add_dependency "ffi"
  s.add_dependency "ffi-rzmq"
  s.add_dependency "redis"
  s.add_dependency "redis-namespace"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", ">= 2.7.0"
  #s.add_development_dependency "zk"
end
