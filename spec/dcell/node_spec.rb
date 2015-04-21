describe DCell::Node do
  def wait_for_actor(id)
    30.times do
      begin
        node = DCell::Node[id]
        return node if node and node.ping 1
      rescue
      end
      # :nocov:
      sleep 1
      # :nocov:
    end
    # :nocov:
    raise "Failed to wait for actor"
    # :nocov:
  end

  before :each do
    id = TEST_NODE[:id]
    @node = wait_for_actor id
    expect(@node.id).to eq(id)

    @unique = SecureRandom.hex
    @node[:test_actor].mutable = @unique
  end

  it "finds all available nodes" do
    nodes = DCell::Node.map
    expect(nodes).to include(DCell.me)
  end

  it "finds remote actors" do
    actor = @node[:test_actor]
    expect(actor.value).to eq(42)
  end

  it "lists remote actors" do
    expect(@node.actors).to include :test_actor
    expect(@node.all).to include :test_actor
  end

  it "failes to attach to obviously dead node" do
    expect {DCell::Node.new("corpse", nil)}.to raise_error DCell::DeadNodeError
  end

  it "fails to send complex structures" do
    actor = @node[:test_actor]
    expect {actor.win(->() {'magic'})}.to raise_error
  end

  it "provides fancy name during inspection" do
    expect(@node.inspect).to start_with "#<DCell::Node[#{TEST_NODE[:id]}]"
  end

  context :crashing do
    after :each do
      id = TEST_NODE[:id]
      @node = wait_for_actor id
      expect(@node.id).to eq(id)
    end

    def wait_for_death(time)
      sleep time + 1
      30.times do
        begin
          actor = DCell[:test_actor].first
          return if actor and actor.mutable != @unique
        rescue
        end
        # :nocov:
        sleep 1
        # :nocov:
      end
      # :nocov:
      raise "Failed to wait for actor death"
      # :nocov:
    end

    it "raises exception on a sync call to dead actor" do
      actor = @node[:test_actor]
      actor.suicide 1
      wait_for_death 1
      expect {actor.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on a sync call to dead actor even if it was killed" do
      actor = @node[:test_actor]
      actor.suicide 1, :KILL
      wait_for_death 1
      expect {actor.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on access to the value of future operation if remote actor dies" do
      actor = @node[:test_actor]
      actor.async.suicide 0, :KILL
      future = actor.future.value
      wait_for_death 0
      expect {future.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on access to the value of future operation which crashed the actor" do
      actor = @node[:test_actor]
      future = actor.future.suicide 0, :KILL
      wait_for_death 0
      expect {p future.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on sync operation if remote actor dies during async operation" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      wait_for_death 0
      expect {actor.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on async operation if remote actor dies during async operation" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      wait_for_death 0
      expect {actor.async}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on future operation if remote actor dies during async operation" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      wait_for_death 0
      expect {actor.future}.to raise_error Celluloid::DeadActorError
    end
  end
end
