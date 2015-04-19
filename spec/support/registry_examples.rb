shared_context "a DCell registry" do
  context "node registry" do
    address = "tcp://localhost:7777"
    meta = {address: address, actors: ["one", "two", "three"], ttl: Time.now.to_i}

    before :each do
      subject.clear_all_nodes
    end

    it "stores node address and other properties" do
      subject.set_node("foobar", meta)
      expect(subject.get_node("foobar")).to eq(meta)
    end

    it "stores the IDs of all nodes" do
      subject.set_node("foobar", meta)
      expect(subject.nodes).to include "foobar"
    end
  end

  context "global registry" do
    before :each do
      subject.clear_globals
    end

    it "stores values" do
      subject.set_global("foobar", [1,2,3])
      expect(subject.get_global("foobar")).to eq([1,2,3])
    end

    it "stores the keys of all globals" do
      subject.set_global("foobar", true)
      expect(subject.global_keys).to include "foobar"
    end
  end
end
