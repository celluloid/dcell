shared_context "a DCell registry" do
  context "node registry" do
    address = "tcp://localhost:7777"
    meta = {address: address, actors: ["one", "two", "three"]}

    before :each do
      subject.clear_all_nodes
    end

    it "stores node address and other properties" do
      subject.set_node("foobar", meta)
      subject.get_node("foobar").should == meta
    end

    it "stores the IDs of all nodes" do
      subject.set_node("foobar", meta)
      subject.nodes.should include "foobar"
    end
  end

  context "global registry" do
    before :each do
      subject.clear_globals
    end

    it "stores values" do
      subject.set_global("foobar", [1,2,3])
      subject.get_global("foobar").should == [1,2,3]
    end

    it "stores the keys of all globals" do
      subject.set_global("foobar", true)
      subject.global_keys.should include "foobar"
    end
  end
end
