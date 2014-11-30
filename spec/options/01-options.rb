TEST_DB = {
  :redis => {:server => 'localhost', :env => 'test'},
  :zk => {:server => 'localhost', :env => 'test'},
  :mongodb => {:db => 'dcell-test'},
  :cassandra => {},
}
TEST_NODE = {
  :id => 'test_node',
  :addr => "127.0.0.1",
  :port => '*',
}
