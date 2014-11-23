require 'spec_helper'

describe DCell do
  it "raises exception on unknown registry provider" do
    expect {DCellMock.setup :registry => {:adapter => nil}}.to raise_error(ArgumentError, "no registry adapter given in config")
    expect {DCellMock.setup :registry => {:adapter => 'invalid'}}.to raise_error(ArgumentError, "invalid registry adapter: invalid")
  end

  it "uses unique method of registry to generate node ID" do
    DCellMock.setup :registry => {:adapter => 'dummy', :seed => Math::PI}
    DCellMock.id.should == Math::PI
  end

  it "accepts node ID as optional setup parameter" do
    DCellMock.setup :id => Math::E, :registry => {:adapter => 'dummy'}
    DCellMock.id.should == Math::E
  end

  it "tries to generate node ID if registry does not define :unique method and no explicit setup parameter given" do
    DCellMock.setup :registry => {:adapter => 'noop'}
    DCellMock.id.should_not == nil
  end
end
