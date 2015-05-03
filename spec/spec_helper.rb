require 'rubygems'
require 'bundler/setup'
require 'coveralls'
Coveralls.wear_merged!
SimpleCov.merge_timeout 3600
SimpleCov.command_name 'spec'

SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter

require 'dcell'
Dir['./spec/options/*.rb'].map { |f| require f }
Dir['./spec/support/*.rb'].map { |f| require f }

Celluloid.logger = nil
Celluloid.shutdown_timeout = 1

RSpec.configure(&:disable_monkey_patching!)

RSpec.configure do |config|
  config.before(:suite) do
    DCell.start test_options

    DCell::Directory["deadman"].address = "tcp://localhost:-1"
    DCell::Directory["deadman"].actors = [:test_actor]

    DCell::Directory["corpse"].address = "tcp://localhost:-2"
    DCell::Directory["corpse"].actors = [:test_actor]
    DCell::Directory["corpse"].update_ttl Time.at 0
  end

  config.after(:suite) do
    node = DCell::Node[TEST_NODE[:id]]
    node.terminate if node
  end
end
