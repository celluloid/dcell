def test_options
  options = {}
  adapter = TEST_ADEPTER
  if adapter
    options[:registry] = {:adapter => adapter}
    options[:registry].merge! TEST_DB[adapter.to_sym]
  end
  options['heartbeat_rate'] = 1
  options['heartbeat_timeout'] = 2
  options
end
