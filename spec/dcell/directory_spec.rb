describe DCell::Directory do
  it "stores node addresses" do
    DCell::Directory["foobar"] = "tcp://localhost:1870"
    DCell::Directory["foobar"].should == "tcp://localhost:1870"
  end
  it "presents all stored addresses" do
    DCell::Directory["foo"] = "tcp://fooaddress"
    DCell::Directory["bar"] = "tcp://baraddress"
    DCell::Directory.all.should include("foo")
    DCell::Directory.all.should include("bar")
  end
  it "clears node addresses" do
    DCell::Directory["foo"] = "tcp://fooaddress"
    DCell::Directory["foobar"].should == "tcp://localhost:1870"
    ["foo", "foobar"].each do |node|
      DCell::Directory.remove node
    end
    DCell::Directory["foobar"].should_not == "tcp://localhost:1870"
  end
end
