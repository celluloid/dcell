require 'rubygems'
require 'bundler/setup'
require 'coveralls'
Coveralls.wear!

require 'dcell'
Dir['./spec/support/*.rb'].map { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    DCell.setup
    DCell.run!

    TestNode.start
    TestNode.wait_until_ready
  end

  config.after(:suite) do
    TestNode.stop
  end
end
