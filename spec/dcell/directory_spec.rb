require 'spec_helper'

describe DCell::Directory do
  it "stores node addresses" do
    DCell::Directory["foobar"] = "tcp://localhost:1870"
    DCell::Directory["foobar"].should == "tcp://localhost:1870"
  end
end
