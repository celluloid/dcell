require 'spec_helper'
require 'dcell/registries/zk_adapter'

describe DCell::Registry::ZkAdapter do
  subject { DCell::Registry::ZkAdapter.new :server => 'localhost', :env => 'test' }
  it_behaves_like "a DCell registry"
end