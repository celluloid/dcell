require 'spec_helper'

describe Celluloid, "extensions" do
  class WillKane
    include Celluloid
  end

  it "marshals actors" do
    marshal = WillKane.new
    Marshal.dump(marshal).should be_a(String)
  end
end
