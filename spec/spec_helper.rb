require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell'
Dir['./spec/support/*.rb'].map { |f| require f }

DCell.setup :registry => { :adapter => 'gossip', :server => { :id => 'test_node', :addr => "tcp://127.0.0.1:#{TestNode::PORT}" } }
DCell.run!

TestNode.start
TestNode.wait_until_ready

at_exit do
  TestNode.stop
end
