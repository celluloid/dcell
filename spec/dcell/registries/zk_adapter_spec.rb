require 'dcell/registries/zk_adapter'

describe DCell::Registry::ZkAdapter, :pending => TEST_ADEPTER != 'zk' && "no zookeeper" do
  subject { DCell::Registry::ZkAdapter.new TEST_DB[:zk] }
  it_behaves_like "a DCell registry"
end
