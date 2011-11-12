require 'spec_helper'

describe DCell::ZookeeperAdapter do
  subject { DCell::ZookeeperAdapter.new :server => 'localhost', :env => 'test' }
  it_behaves_like "a DCell registry"
end