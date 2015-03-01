module DCell
  # A node in a DCell cluster
  class Node
    # Exception raised when no response was received within a given timeout
    class NoResponseError < Exception; end

    # Exception raised when remote node appears dead
    class DeadNodeError < Exception; end

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
      @socket = nil
      @ttl = nil
      @heartbeat = nil
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
      send_request request, timeout
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
      NodeCache.delete id
      MailboxManager.delete Thread.mailbox
      Logger.info "Disconnected from #{id}"
    end

    # Update remote node addr
    def addr=(addr)
      @addr = addr
    end

    # Obtain the node's 0MQ socket
    def socket
      return @socket if @socket

      @socket = Celluloid::ZMQ::PushSocket.new
      begin
        unless @addr
          Logger.info "No address for #{id}"
          raise IOError.new
        end
        @socket.connect @addr
        @socket.linger = @heartbeat_timeout * 1000
      rescue IOError
        @socket.close
        @socket = nil
        raise
      end
      @addr = @socket.get(::ZMQ::LAST_ENDPOINT).strip

      transition :connected
      @socket
    end

    # Pack and send a message to another DCell node
    def send_message(message)
      begin
        message = message.to_msgpack
      rescue => e
        abort e
      end
      socket << message
    end
    alias_method :<<, :send_message

    # Send request and wait for response
    def push_request(request, timeout=nil)
      send_message request
      save_request request
      response = receive(timeout) do |msg|
        msg.respond_to?(:request_id) && msg.request_id == request.id
      end
      delete_request request
      abort NoResponseError.new unless response
      response
    end

    # Send request and handle unroll response
    def send_request(request, timeout=nil)
      response = push_request request, timeout
      return if response.is_a? CancelResponse
      if response.is_a? ErrorResponse
        klass = Utils::full_const_get response.value[:class]
        msg = response.value[:msg]
        raise klass.new msg
      end
      response.value
    end

    # Relay message to remote actor
    def relay(message)
      request = Message::Relay.new(Thread.mailbox, message)
      send_request request
    end

    # Relay async message to remote actor
    def async_relay(message)
      request = Message::Relay.new(Thread.mailbox, message)
      send_message request
    end

    # Goodbye message to remote actor
    def farewell
      request = Message::Farewell.new
      send_message request
    end

    # Send a heartbeat message after the given interval
    def send_heartbeat
      return if DCell.id == id
      send_message DCell::Message::Heartbeat.new id
      @heartbeat = after(@heartbeat_rate) { send_heartbeat }
    end

    # Handle an incoming heartbeat for this node
    def handle_heartbeat(from)
      return if from == id
      transition :connected
      transition :partitioned, delay: @heartbeat_timeout
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
