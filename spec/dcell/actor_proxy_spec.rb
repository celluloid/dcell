describe DCell::ActorProxy do
  before :all do
    @node = DCell::Node[TEST_NODE[:id]]
    @node.id.should == TEST_NODE[:id]
    @remote_actor = @node[:test_actor]

    class LocalActor
      include Celluloid

      attr_reader :crash_reason
      trap_exit   :exit_handler

      def initialize
        @crash_reason = nil
      end

      def exit_handler(actor, reason)
        @crash_reason = reason
      end
    end
  end

  it "makes synchronous calls to remote actors" do
    @remote_actor.value.should == 42
  end

  it "handles blocks" do
    result = nil
    @remote_actor.win do |value|
      result = value
    end
    result.should == 10000
  end

  it "makes future calls to remote actors", :pending => true do
    @remote_actor.future(:value).value.should == 42
  end

  it "does not support remote kill", :pending => true do
    expect {Celluloid::Actor.kill @remote_actor}.to raise_error NotImplementedError, "remote kill not supported"
  end

  it "does not support remote join", :pending => true do
    expect {Celluloid::Actor.join @remote_actor}.to raise_error NotImplementedError, "remote join not supported"
  end

  context :linking, :pending => true do
    before :each do
      @local_actor = LocalActor.new
    end

    it "links to remote actors" do
      @local_actor.link @remote_actor
      @local_actor.linked_to?(@remote_actor).should be_true
      @remote_actor.linked_to?(@local_actor).should be_true
    end

    it "unlinks from remote actors" do
      @local_actor.link @remote_actor
      @local_actor.unlink @remote_actor

      @local_actor.linked_to?(@remote_actor).should be_false
      @remote_actor.linked_to?(@local_actor).should be_false
    end

    it "traps exit messages from other actors" do
      @local_actor.link @remote_actor

      expect do
        @remote_actor.crash
      end.to raise_exception(RuntimeError)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      @local_actor.crash_reason.should be_a(RuntimeError)
      @local_actor.crash_reason.message.should == "the spec purposely crashed me :("
    end
  end
end
