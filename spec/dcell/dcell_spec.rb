describe DCell do
  it "raises exception on unknown registry provider" do
    expect {DCellMock.setup}.to raise_error(ArgumentError, "no registry adapter given in config")
  end

  it "uses unique method of registry to generate node ID" do
    registry = DCell::Registry::DummyAdapter.new seed: Math::PI
    DCellMock.setup registry: registry
    expect(DCellMock.id).to eq(Math::PI)
  end

  it "accepts node ID as optional setup parameter" do
    registry = DCell::Registry::DummyAdapter.new({})
    DCellMock.setup id: Math::E, registry: registry
    expect(DCellMock.id).to eq(Math::E)
  end

  it "tries to generate node ID if registry does not define :unique method and no explicit setup parameter given" do
    registry = DCell::Registry::NoopAdapter.new({})
    DCellMock.setup registry: registry
    expect(DCellMock.id).not_to eq(nil)
  end

  it "finds remote actors" do
    actor = DCell[:test_actor].first
    expect(actor.value).to eq(42)
  end

  it "properly handles messages to non-existant actors" do
    node = DCell::Node[TEST_NODE[:id]]
    actor = DCell::ActorProxy.create.new(node, :ghost, ['whooo'])
    expect {actor.whooo}.to raise_error NoMethodError
  end

  it "properly handles responses to already terminated actors" do
    node = DCell::Node[TEST_NODE[:id]]

    request = DCell::Message::Ping.new({id: nil, address: nil})
    node.send_message request

    request = DCell::Message::Ping.new({id: DCell.id, address: nil})
    node.send_message request

    actor = node[:test_actor]
    expect(actor.value).to eq(42)
  end
end
