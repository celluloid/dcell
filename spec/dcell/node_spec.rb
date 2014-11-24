describe DCell::Node do
  before do
    @node = DCell::Node[TEST_NODE[:id]]
    @node.id.should == TEST_NODE[:id]
  end

  it "finds all available nodes" do
    nodes = DCell::Node.all
    nodes.should include(DCell.me)
  end

  it "finds remote actors" do
    actor = @node[:test_actor]
    actor.value.should == 42
  end

  it "lists remote actors" do
    @node.actors.should include :test_actor
    @node.all.should include :test_actor
  end
end
