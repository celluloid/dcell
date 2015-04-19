describe Celluloid, "extensions" do
  before do
    class WillKane
      include Celluloid
    end
    @marshal = WillKane.new
  end

  it "packs Celluloid::Mailbox objects" do
    expect(@marshal.mailbox).to be_a(Celluloid::Mailbox)
    bin = @marshal.mailbox.to_msgpack
    mailbox = MessagePack.unpack(bin)
    expect(mailbox['address']).to eq(@marshal.mailbox.address)
    expect(mailbox['id']).to eq(DCell.id)
  end
end
