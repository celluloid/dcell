require 'spec_helper'
require 'dcell/registries/zk_adapter'

describe DCell::Registry::ZkAdapter, :pending => ENV["CI"] && "no zookeeper" do
  subject { DCell::Registry::ZkAdapter.new :server => 'localhost', :env => 'test' }
  it_behaves_like "a DCell registry"
end
