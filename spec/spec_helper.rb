require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell'
Dir['./spec/support/*.rb'].map { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    DCell.setup :directory => { :id => 'test_node', :addr => "tcp://127.0.0.1:#{TestNode::PORT}" }
    @supervisor = DCell.run!

    TestNode.start
    TestNode.wait_until_ready
  end

  config.after(:suite) do
    TestNode.stop
  end
end