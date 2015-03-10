require 'uri'

module DCell
  # Exception raised when no response was received within a given timeout
  class NoResponseError < Exception; end

  # Exception raised when remote node appears dead
  class DeadNodeError < Exception; end

  class RelayServer
    attr_accessor :addr

    def initialize
      uri = URI(DCell.addr)
      @addr = "#{uri.scheme}://#{uri.host}:*"
      @server = Server.new self
    end

    def terminate
      @server.terminate if @server.alive?
    end
  end


  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM

    attr_reader :id

    finalizer :shutdown

    # FSM
    default_state :disconnected
    state :shutdown
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
      @id, @addr = id, addr
      @requests = ResourceManager.new
      @actors = ResourceManager.new
      @remote_dead = false

      @heartbeat_rate    = DCell.heartbeat_rate  # How often to send heartbeats in seconds
      @heartbeat_timeout = DCell.heartbeat_timeout # How soon until a lost heartbeat triggers a node partition
      @ttl_rate = DCell.ttl_rate # How often update TTL in the registry

      if server
        update_ttl
      elsif not Directory[@id].alive?
        Logger.warn "Node '#{@id}' looks dead"
        raise DeadNodeError.new
      end

      # Total hax to accommodate the new Celluloid::FSM API
      attach self
    end

    # Find an call registered with a given name on this node
    def find(name)
      request = Message::Find.new(Thread.mailbox, name)
      methods = send_request request
      return nil if methods.kind_of? NilClass
      actor = DCell::ActorProxy.new self, name, methods
      add_actor actor
    end
    alias_method :[], :find

    # List all registered actors on this node
    def actors
      request = Message::List.new(Thread.mailbox)
      list = send_request request
      list.map! do |entry|
        entry.to_sym
      end
    end
    alias_method :all, :actors

    # Send a ping message with a given timeout
    def ping(timeout=nil)
      request = Message::Ping.new(Thread.mailbox)
      send_request request, :default, timeout
    end

    # Friendlier inspection
    def inspect
      "#<DCell::Node[#{@id}] @addr=#{@addr.inspect}>"
    end

    ##################################################
    # Internal API
    ##################################################

    def save_request(request)
      @requests.register(request.id) {request}
    end

    def delete_request(request)
      @requests.delete request.id
    end

    def cancel_requests
      @requests.each do |id, request|
        address = request.sender.address
        rsp = CancelResponse.new id, address
        rsp.dispatch
      end
    end

    def add_actor(actor)
      @actors.register(actor.object_id) {actor}
    end

    def kill_actors
      @actors.clear do |id, actor|
        actor.terminate rescue Celluloid::DeadActorError
      end
    end

    def detach
      kill_actors
      cancel_requests
      @remote_dead = true
      terminate
    end

    # Graceful termination of the node
    def shutdown
      transition :shutdown
      unless @remote_dead or DCell.id == id
        kill_actors
        farewell if Directory[id].alive? rescue IOError
      end
      @socket.close if @socket
      @rsocket.close if @rsocket
      @rserver.terminate if @rserver
      NodeCache.delete id
      MailboxManager.delete Thread.mailbox
      Logger.info "Disconnected from #{id}"
    end

    # Obtain the node's 0MQ socket
    def __socket(addr)
      raise IOError unless addr

      socket = Celluloid::ZMQ::PushSocket.new
      begin
        socket.connect addr
        socket.linger = @heartbeat_timeout * 1000
      rescue IOError
        socket.close
        socket = nil
        raise
      end
      socket
    end

    # Obtain socket for relay messages
    def rsocket
      return @rsocket if @rsocket
      send_relayopen unless @raddr
      @rsocket = __socket @raddr
    end

    # Obtain socket for management messages
    def socket
      return @socket if @socket
      @socket = __socket @addr
      transition :connected
      @socket
    end

    # Pack and send a message to another DCell node
    def send_message(message, pipe=:default)
      queue = nil
      if pipe == :default
        queue = socket
      elsif pipe == :relay
        queue = rsocket
      end

      begin
        message = message.to_msgpack
      rescue => e
        abort e
      end
      queue << message
    end

    # Send request and wait for response
    def push_request(request, pipe=:default, timeout=nil)
      send_message request, pipe
      save_request request
      response = receive(timeout) do |msg|
        msg.respond_to?(:request_id) && msg.request_id == request.id
      end
      delete_request request
      abort NoResponseError.new unless response
      response
    end

    # Send request and handle unroll response
    def send_request(request, pipe=:default, timeout=nil)
      response = push_request request, pipe, timeout
      return if response.is_a? CancelResponse
      if response.is_a? ErrorResponse
        klass = Utils::full_const_get response.value[:class]
        msg = response.value[:msg]
        abort klass.new msg
      end
      response.value
    end

    # Relay message to remote actor
    def relay(message)
      request = Message::Relay.new(Thread.mailbox, message)
      send_request request, :relay
    end

    # Relay async message to remote actor
    def async_relay(message)
      request = Message::Relay.new(Thread.mailbox, message)
      send_message request, :relay
    end

    # Goodbye message to remote actor
    def farewell
      request = Message::Farewell.new
      send_message request
    end

    # Send a heartbeat message after the given interval
    def send_heartbeat
      return if DCell.id == id
      request = DCell::Message::Heartbeat.new id
      send_message request
      @heartbeat = after(@heartbeat_rate) { send_heartbeat }
    end

    # Handle an incoming heartbeat for this node
    def handle_heartbeat(from)
      return if from == id
      transition :connected
      transition :partitioned, delay: @heartbeat_timeout
    end

    # Send an advertising message
    def send_relayopen
      meta = {raddr: rserver.addr}
      request = Message::RelayOpen.new(Thread.mailbox, id, meta)
      @raddr = send_request request
    end

    # Handle an incoming node advertising message for this node
    def handle_relayopen(from, meta)
      @raddr = meta[:raddr]
    end

    def rserver
      return @rserver if @rserver
      @rserver = RelayServer.new
    end

    # Update TTL in registry
    def update_ttl
      Directory[id].update_ttl
      @ttl = after(@ttl_rate) { update_ttl }
    end

    def on_connected
      send_heartbeat
      unless id == DCell.id
        transition :partitioned, delay: @heartbeat_timeout
      end
      Logger.info "Connected to #{id}"
    end

    def on_partitioned
      @heartbeat.cancel if @heartbeat
      @ttl.cancel if @ttl
      Logger.warn "Communication with #{id} interrupted"
      detach
    end
  end
end
