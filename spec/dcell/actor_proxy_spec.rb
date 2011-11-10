require 'spec_helper'

describe DCell::ActorProxy do
  before do
    @node = DCell::Node['test_node']
    @node.id.should == 'test_node'

    @actor = @node[:test_actor]
    @actor.class.should == DCell::ActorProxy
  end

  it "makes synchronous calls to remote actors" do
    @actor.value.should == 42
  end
end
