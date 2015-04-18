describe DCell::Directory do
  after :each do
    ["foo", "bar", "foobar"].each do |id|
      DCell::Directory.remove id
    end
  end

  it "stores node addresses" do
    DCell::Directory["foobar"].address = "tcp://localhost:1870"
    expect(DCell::Directory["foobar"].address).to eq("tcp://localhost:1870")
  end

  it "stores node actors" do
    DCell::Directory["foobar"].actors = []
    DCell::Directory["foobar"] << :one
    DCell::Directory["foobar"] << :two
    expect(DCell::Directory["foobar"].actors).to eq([:one, :two])

    DCell::Directory["foobar"].actors = [:three, :four]
    expect(DCell::Directory["foobar"].actors).to eq([:three, :four])
  end

  it "presents all stored addresses" do
    DCell::Directory["foo"].address = "tcp://fooaddress"
    DCell::Directory["bar"].address = "tcp://baraddress"
    expect(DCell::Directory.to_a).to include("foo")
    expect(DCell::Directory.to_a).to include("bar")
  end

  it "clears node addresses" do
    DCell::Directory["foobar"].address = "tcp://fooaddress"
    expect(DCell::Directory["foobar"].address).to eq("tcp://fooaddress")
    DCell::Directory.remove "foobar"
    expect(DCell::Directory["foobar"].address).not_to eq("tcp://fooaddress")
  end
end
