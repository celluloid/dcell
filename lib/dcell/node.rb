module DCell
  # Exception raised when no response was received within a given timeout
  class NoResponseError < StandardError; end

  # Exception raised when remote node appears dead
  class DeadNodeError < StandardError; end

  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM

    include DCell::Node::Communication
    include DCell::Node::RPC
    include DCell::Node::Actors

    attr_reader :id

    finalizer :shutdown

    # FSM
    default_state :disconnected
    state :shutdown do
      on_shutdown
    end
    state :disconnected, to: [:connected, :shutdown]
    state :connected do
      on_connected
    end
    state :partitioned do
      on_partitioned
    end

    # Access sugar to NodeManager methods
    class << self
      include Enumerable
      extend Forwardable
      include NodeManager
    end

    def initialize(id, addr, server=false)
      super self # FSM's constructor

      @id = id

      init_rpc
      init_actors
      init_defaults
      init_comm addr

      if server
        update_ttl
      elsif !Directory[@id].alive?
        Logger.warn "Node '#{@id}' looks dead"
        fail DeadNodeError
      end
    end

    # Find an call registered with a given name on this node
    def find(name)
      request = Message::Find.new(Thread.mailbox, name)
      methods = send_request request
      return nil if methods.is_a? NilClass
      rsocket # open relay pipe to avoid race conditions
      actor = DCell::ActorProxy.create.new self, name, methods
      add_actor actor
    end
    alias_method :[], :find

    # List all registered actors on this node
    def actors
      request = Message::List.new(Thread.mailbox)
      list = send_request request
      list.map!(&:to_sym)
    end
    alias_method :all, :actors

    # Send a ping message with a given timeout
    def ping(timeout=nil)
      request = Message::Ping.new(Thread.mailbox)
      send_request request, :request, timeout
    end

    # Friendlier inspection
    def inspect
      "#<DCell::Node[#{@id}] @addr=#{@addr.inspect}>"
    end

    ##################################################
    # Internal API
    ##################################################

    def init_defaults
      @ttl = nil

      @heartbeat_rate    = DCell.heartbeat_rate
      @heartbeat_timeout = DCell.heartbeat_timeout
      @request_timeout   = DCell.request_timeout
      @ttl_rate          = DCell.ttl_rate
    end

    def detach
      kill_actors
      cancel_requests
      remote_dead
      terminate
    end

    # Graceful termination of the node
    def shutdown
      transition :shutdown
      farewell
      kill_actors
      close_comm
      NodeCache.delete @id
      MailboxManager.delete Thread.mailbox
      instance_variables.each { |iv| remove_instance_variable iv }
    end

    # Update TTL in registry
    def update_ttl
      Directory[@id].update_ttl
      @ttl = after(@ttl_rate) { update_ttl }
    end

    def on_shutdown
      Logger.info "Disconnected from #{@id}"
    end

    def on_connected
      send_heartbeat
      transition :partitioned, delay: @heartbeat_timeout unless @id == DCell.id
      Logger.info "Connected to #{@id}"
    end

    def on_partitioned
      @heartbeat.cancel if @heartbeat
      @ttl.cancel if @ttl
      Logger.warn "Communication with #{@id} interrupted"
      detach
    end
  end
end
