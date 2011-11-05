require 'spec_helper'

describe Celluloid, "extensions" do
  before do
    class WillKane
      include Celluloid
    end
    @marshal = WillKane.new
  end

  it "marshals Celluloid::ActorProxy objects" do
    string = Marshal.dump(@marshal)
    Marshal.load(string).should be_a(DCell::ActorProxy)
  end

  it "marshals Celluloid::Mailbox objects" do
    @marshal.mailbox.should be_a(Celluloid::Mailbox)
    string = Marshal.dump(@marshal.mailbox)
    Marshal.load(string).should be_a(DCell::MailboxProxy)
  end
end
