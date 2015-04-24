require 'dcell/registries/redis_adapter'

RSpec.describe DCell::Registry::RedisAdapter, skip: TEST_ADEPTER != 'redis' && "no redis" do
  subject { DCell::Registry::RedisAdapter.new TEST_DB[:redis] }
  it_behaves_like "a DCell registry"
end
