create keyspace test with placement_strategy = 'org.apache.cassandra.locator.SimpleStrategy' and strategy_options = {replication_factor:1};
use test;
create column family dcell;
