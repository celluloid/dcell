require 'spec_helper'

describe DCell::Node do
  before do
    @node = DCell::Node['test_node']
    @node.id.should == 'test_node'
  end

  it "looks up remote actors" do
    actor = @node[:test_actor]
    actor.class.should == DCell::ActorProxy
  end
end
