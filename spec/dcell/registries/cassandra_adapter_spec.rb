require 'dcell/registries/cassandra_adapter'

describe DCell::Registry::CassandraAdapter, :pending => TEST_ADEPTER != 'cassandra' && "no cassandra" do
  subject { DCell::Registry::CassandraAdapter.new TEST_DB[:cassandra] }
  it_behaves_like "a DCell registry"
end
