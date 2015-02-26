describe DCell::Directory do
  after :each do
    ["foo", "bar", "foobar"].each do |id|
      DCell::Directory.remove id
    end
  end

  it "stores node addresses" do
    DCell::Directory["foobar"].address = "tcp://localhost:1870"
    DCell::Directory["foobar"].address.should == "tcp://localhost:1870"
  end

  it "stores node actors" do
    DCell::Directory["foobar"].actors = []
    DCell::Directory["foobar"] << :one
    DCell::Directory["foobar"] << :two
    DCell::Directory["foobar"].actors.should == [:one, :two]

    DCell::Directory["foobar"].actors = [:three, :four]
    DCell::Directory["foobar"].actors.should == [:three, :four]
  end

  it "presents all stored addresses" do
    DCell::Directory["foo"].address = "tcp://fooaddress"
    DCell::Directory["bar"].address = "tcp://baraddress"
    DCell::Directory.map{|node| node.id}.should include("foo")
    DCell::Directory.map{|node| node.id}.should include("bar")
  end

  it "clears node addresses" do
    DCell::Directory["foobar"].address = "tcp://fooaddress"
    DCell::Directory["foobar"].address.should == "tcp://fooaddress"
    DCell::Directory.remove "foobar"
    DCell::Directory["foobar"].address.should_not == "tcp://fooaddress"
  end
end
