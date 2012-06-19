require 'spec_helper'

__END__

describe DCell::Registry::GossipAdapter do
  subject { DCell::Registry::GossipAdapter.new :env => "test" }
  it_behaves_like "a DCell registry"
end
