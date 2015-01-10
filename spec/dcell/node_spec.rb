describe DCell::Node do
  def wait_for_actor(id)
    30.times do
      node = DCell::Node[id]
      begin
        return node if node and node.all
      rescue Celluloid::DeadActorError, Celluloid::Task::TerminatedError
      end
      sleep 1
    end
  end

  before :each do
    @node = wait_for_actor TEST_NODE[:id]
    @node.id.should == TEST_NODE[:id]
  end

  it "finds all available nodes" do
    nodes = DCell::Node.all
    nodes.should include(DCell.me)
  end

  it "finds remote actors" do
    actor = @node[:test_actor]
    actor.value.should == 42
  end

  it "lists remote actors" do
    @node.actors.should include :test_actor
    @node.all.should include :test_actor
  end

  context :crashing, :pending => RUBY_ENGINE=="jruby" do
    it "retries remote actor lookup" do
      @node[:test_actor].suicide 3
      sleep 4
      @node[:test_actor].value.should == 42
    end

    def wait_for_death(actor)
      10.times do
        break unless actor.alive?
        sleep 1
      end
    end

    it "raises exception on a sync call to dead actor" do
      actor = @node[:test_actor]
      actor.suicide 3
      wait_for_death actor
      expect {actor.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on access to the value of future operation if remote actor dies" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      future = actor.future.value
      wait_for_death actor
      expect {future.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on access to the value of future operation which crashed the actor" do
      actor = @node[:test_actor]
      future = actor.future.suicide 0
      wait_for_death actor
      expect {future.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on sync operation if remote actor dies during async operation" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      wait_for_death actor
      expect {actor.value}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on async operation if remote actor dies during async operation" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      wait_for_death actor
      expect {actor.async}.to raise_error Celluloid::DeadActorError
    end

    it "raises exception on future operation if remote actor dies during async operation" do
      actor = @node[:test_actor]
      actor.async.suicide 0
      wait_for_death actor
      expect {actor.future}.to raise_error Celluloid::DeadActorError
    end
  end
end
