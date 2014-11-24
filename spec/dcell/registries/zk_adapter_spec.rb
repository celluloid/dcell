require 'dcell/registries/zk_adapter'

describe DCell::Registry::ZkAdapter, :pending => TEST_ADEPTER != 'zk' && "no zookeeper" do
  subject { DCell::Registry::ZkAdapter.new TEST_DB[:zk] }
  it_behaves_like "a DCell registry" do
    context "when one znode changes" do
      it "updates a node" do
        expect(DCell::Node).to receive(:update).with("foo")
        subject.set_node("foo", "tcp://fooaddress")
        # WARNING: only by calling get_node we renew the watcher
        subject.get_node("foo").should eq("tcp://fooaddress")
        subject.set_node("foo", "tcp://newaddress")
        sleep 0.8 # takes some time to zookeeper watchers to take full effect
      end
    end
    context "when one znode is deleted" do
      it "deletes a node" do
        expect(DCell::Node).to receive(:remove).with("foo")
        subject.set_node("foo", "tcp://fooaddress")
        # WARNING: only by calling get_node we renew the watcher
        subject.get_node("foo").should eq("tcp://fooaddress")
        subject.remove_node "foo"
        sleep 0.8 # takes some time to zookeeper watchers to take full effect
      end
    end
  end
end
