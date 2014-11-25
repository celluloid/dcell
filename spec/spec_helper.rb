require 'rubygems'
require 'bundler/setup'
require 'coveralls'
Coveralls.wear_merged!
SimpleCov.merge_timeout 3600
SimpleCov.command_name 'spec'

require 'dcell'
Dir['./spec/options/*.rb'].map { |f| require f }
Dir['./spec/support/*.rb'].map { |f| require f }

RSpec.configure do |config|
  config.before(:suite) do
    options = {}
    options.merge! test_db_options
    begin
      DCell.start options
    rescue => e
      puts e
      raise
    end
  end
end
