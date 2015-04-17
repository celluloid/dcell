module DCell
  # Exception raised when no response was received within a given timeout
  class NoResponseError < Exception; end

  # Exception raised when remote node appears dead
  class DeadNodeError < Exception; end

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
      @leech = false

      @heartbeat_rate    = DCell.heartbeat_rate
      @heartbeat_timeout = DCell.heartbeat_timeout
      @request_timeout   = DCell.request_timeout
      @ttl_rate          = DCell.ttl_rate

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
      send_request request, :request, timeout
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
      unless @remote_dead or DCell.id == @id
        kill_actors
        farewell
      end
      @socket.terminate if @socket && @socket.alive?
      @rsocket.terminate if @rsocket && @rsocket.alive?
      @rserver.terminate if @rserver && @rserver.alive?
      NodeCache.delete @id
      MailboxManager.delete Thread.mailbox
      Logger.info "Disconnected from #{@id}"
      instance_variables.each { |iv| remove_instance_variable iv }
    end

    # Obtain socket for relay messages
    def rsocket
      return @rsocket if @rsocket
      send_relayopen unless @raddr
      @rsocket = ClientServer.new @raddr, @heartbeat_timeout*1000
    end

    # Obtain socket for management messages
    def socket
      return @socket if @socket
      @socket = ClientServer.new @addr, @heartbeat_timeout*1000
      @socket.farewell = true
      transition :connected
      @socket
    end

    # Pack and send a message to another DCell node
    def send_message(message, pipe=:request)
      queue = nil
      if pipe == :request
        queue = socket
      elsif pipe == :response
        queue = Celluloid::Actor[:server]
      elsif pipe == :relay
        queue = rsocket
      end

      begin
        message = message.to_msgpack
      rescue => e
        abort e
      end
      queue.write @id, message
    end

    # Send request and wait for response
    def push_request(request, pipe=:request, timeout=@request_timeout)
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
    def send_request(request, pipe=:request, timeout=nil)
      response = push_request request, pipe, timeout
      return if response.is_a? CancelResponse
      if response.is_a? ErrorResponse
        value = response.value
        klass = Utils::full_const_get value[:class]
        exception = klass.new value[:msg]
        exception.set_backtrace value[:tb]
        abort exception
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
      return unless Directory[@id].alive?
      request = Message::Farewell.new
      send_message request
    rescue
    end

    # Send a heartbeat message after the given interval
    def send_heartbeat
      return if DCell.id == @id
      request = DCell::Message::Heartbeat.new @id
      send_message request, @leech ? :response : :request
      @heartbeat = after(@heartbeat_rate) { send_heartbeat }
    end

    # Handle an incoming heartbeat for this node
    def handle_heartbeat(from)
      return if from == @id
      @leech = true unless state == :connected
      transition :connected
      transition :partitioned, delay: @heartbeat_timeout
    end

    # Send an advertising message
    def send_relayopen
      request = Message::RelayOpen.new(Thread.mailbox)
      @raddr = send_request request
    end

    # Handle an incoming node advertising message for this node
    def handle_relayopen
      @rsocket = rserver
    end

    def rserver
      return @rserver if @rserver
      @rserver = RelayServer.new
    end

    # Update TTL in registry
    def update_ttl
      Directory[@id].update_ttl
      @ttl = after(@ttl_rate) { update_ttl }
    end

    def on_connected
      send_heartbeat
      unless @id == DCell.id
        transition :partitioned, delay: @heartbeat_timeout
      end
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
