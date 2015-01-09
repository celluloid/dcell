describe DCell do
  it "raises exception on unknown registry provider" do
    expect {DCellMock.setup}.to raise_error(ArgumentError, "no registry adapter given in config")
  end

  it "uses unique method of registry to generate node ID" do
    registry = DCell::Registry::DummyAdapter.new :seed => Math::PI
    DCellMock.setup :registry => registry
    DCellMock.id.should == Math::PI
  end

  it "accepts node ID as optional setup parameter" do
    registry = DCell::Registry::DummyAdapter.new({})
    DCellMock.setup :id => Math::E, :registry => registry
    DCellMock.id.should == Math::E
  end

  it "tries to generate node ID if registry does not define :unique method and no explicit setup parameter given" do
    registry = DCell::Registry::NoopAdapter.new({})
    DCellMock.setup :registry => registry
    DCellMock.id.should_not == nil
  end
end
