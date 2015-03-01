def test_options
  options = {}
  # :nocov:
  case TEST_ADEPTER
  when 'redis'
    registry = DCell::Registry::RedisAdapter.new TEST_DB[:redis]
  when 'mongodb'
    registry = DCell::Registry::MongodbAdapter.new TEST_DB[:mongodb]
  when 'cassandra'
    registry = DCell::Registry::CassandraAdapter.new TEST_DB[:cassandra]
  when 'zk'
    registry = DCell::Registry::ZkAdapter.new TEST_DB[:zk]
  end
  # :nocov:
  options[:registry] = registry
  options['heartbeat_rate'] = 1
  options['heartbeat_timeout'] = 2
  options
end
