require 'spec_helper'

describe DCell::Node do
  before do
    @node = DCell::Node['test_node']
    @node.id.should == 'test_node'
  end

  it "finds all available nodes" do
    nodes = DCell::Node.all
    nodes.should include(DCell.me)
  end

  it "finds remote actors" do
    actor = @node[:test_actor]
    actor.value.should == 42
  end  
end
