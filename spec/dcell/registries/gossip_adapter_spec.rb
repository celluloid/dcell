require 'spec_helper'

describe DCell::Registry::GossipAdapter do
  subject { DCell::Registry::GossipAdapter.new :env => "test" }
  it_behaves_like "a DCell registry"
end
