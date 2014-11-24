describe DCell::Registry::RedisAdapter, :pending => TEST_ADEPTER != 'redis' && "no redis" do
  subject { DCell::Registry::RedisAdapter.new TEST_DB[:redis] }
  it_behaves_like "a DCell registry"
end
