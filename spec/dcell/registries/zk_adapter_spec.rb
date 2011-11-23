# The Zookeeper CRuby dependency is pretty annoying :(
# Disabling until this can be spun off into a separate gem
=begin
require 'spec_helper'
require 'dcell/registries/zk_adapter'

describe DCell::Registry::ZkAdapter do
  subject { DCell::Registry::ZkAdapter.new :server => 'localhost', :env => 'test' }
  it_behaves_like "a DCell registry"
end
=end