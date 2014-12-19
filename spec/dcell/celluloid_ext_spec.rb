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

  it "marshals Celluloid::CellProxy objects" do
    string = Marshal.dump(@marshal)
    Marshal.load(string).should be_alive
  end

  it "marshals Celluloid::Mailbox objects" do
    @marshal.mailbox.should be_a(Celluloid::Mailbox)
    string = Marshal.dump(@marshal.mailbox)
    Marshal.load(string).should be_alive
  end

  it "marshals Celluloid::Future objects" do
    future = @marshal.future(:speak)
    future.should be_a(Celluloid::Future)
    string = Marshal.dump(future)
    Marshal.load(string).value.should == "Don't shove me Harv."
  end
end
