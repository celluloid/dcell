RSpec.describe DCell::ActorProxy do
  before :all do
    @node = DCell::Node[TEST_NODE[:id]]
    expect(@node.id).to eq(TEST_NODE[:id])
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
    expect(@remote_actor.value).to eq(42)
  end

  it "makes asynchronous calls to remote actors" do
    magic = 'One dream, one soul, one prize, one goal'
    @remote_actor.async.magic = magic
    expect(@remote_actor.magic).to eq(magic)
  end

  it "handles blocks" do
    result = nil
    @remote_actor.win do |value|
      result = value
    end
    expect(result).to eq(10000)
  end

  it "makes future calls to remote actors" do
    expect(@remote_actor.future(:value).value).to eq(42)
  end

  it "remote actor maintains context" do
    # damn test won't work with multiple clients
    mutable = @remote_actor.mutable
    @remote_actor.mutable = mutable + 1
    expect(@remote_actor.mutable).to eq(mutable + 1)
  end

  context :linking do
    before :each do
      @local_actor = LocalActor.new
    end

    it "links to remote actors" do
      @local_actor.link @remote_actor
      expect(@local_actor.linked_to?(@remote_actor)).to be_truthy
      expect(@remote_actor.linked_to?(@local_actor)).to be_truthy
    end

    it "unlinks from remote actors" do
      @local_actor.link @remote_actor
      @local_actor.unlink @remote_actor

      expect(@local_actor.linked_to?(@remote_actor)).to be_falsey
      expect(@remote_actor.linked_to?(@local_actor)).to be_falsey
    end

    it "traps exit messages from other actors" do
      @local_actor.link @remote_actor

      expect do
        @remote_actor.crash
      end.to raise_exception(RuntimeError)

      sleep 0.1 # hax to prevent a race between exit handling and the next call
      expect(@local_actor.crash_reason).to be_a(RuntimeError)
      expect(@local_actor.crash_reason.message).to eq("the spec purposely crashed me :(")
    end
  end
end
