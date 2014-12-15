describe Celluloid, "extensions" do
  before do
    class WillKane
      include Celluloid

      def speak
        "Don't shove me Harv."
      end
    end
    @marshal = WillKane.new
  end

  it "packs Celluloid::Mailbox objects" do
    @marshal.mailbox.should be_a(Celluloid::Mailbox)
    bin = @marshal.mailbox.to_msgpack
    mailbox = MessagePack.unpack(bin)
    mailbox['address'].should == @marshal.mailbox.address
    mailbox['id'].should == DCell.id
  end
end
