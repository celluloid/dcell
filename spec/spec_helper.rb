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

Celluloid.shutdown_timeout = 1

RSpec.configure do |config|
  config.before(:suite) do
    DCell.start test_db_options
  end
end
