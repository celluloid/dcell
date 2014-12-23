module DCell
  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM
    attr_reader :id, :addr

    finalizer :shutdown

    # FSM
    default_state :disconnected
    state :shutdown
    state :disconnected, :to => [:connected, :shutdown]
    state :connected do
      send_heartbeat
      transition :partitioned, :delay => @heartbeat_timeout
      Logger.info "Connected to #{id}"
    end
    state :partitioned do
      @heartbeat.cancel if @heartbeat
      Logger.warn "Communication with #{id} interrupted"
      move_node
    end

    # Access sugar to NodeManager methods
    class << self
      include Enumerable
      extend Forwardable
      include NodeManager
    end

    def initialize(id, addr)
      @id, @addr = id, addr
      @socket = nil
      @heartbeat = nil
      @requests = ResourceManager.new
      @actors = ResourceManager.new

      @heartbeat_rate    = DCell.heartbeat_rate  # How often to send heartbeats in seconds
      @heartbeat_timeout = DCell.heartbeat_timeout # How soon until a lost heartbeat triggers a node partition

      # Total hax to accommodate the new Celluloid::FSM API
      attach self
    end

    def save_request(request)
      return if request.kind_of? Message::Relay
      @requests.register(request.id) {request}
    end

    def delete_request(request)
      return if request.kind_of? Message::Relay
      @requests.delete request.id
    end

    def retry_requests
      @requests.each do |id, request|
        address = request.sender.address
        rsp = RetryResponse.new id, address
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

    def move_node
      addr = Directory[id]
      kill_actors
      if addr
        update_client_address addr
        retry_requests
      else
        terminate
      end
    end

    def update_client_address(addr)
      @heartbeat.cancel if @heartbeat
      @addr = addr
      if @socket
        @socket.close
        @socket = nil
      end
      socket
    end

    def update_server_address(addr)
      @addr = addr
    end

    def shutdown
      transition :shutdown
      @socket.close if @socket
      NodeCache.delete id
      MailboxManager.delete Thread.mailbox
    end

    # Obtain the node's 0MQ socket
    def socket
      return @socket if @socket

      @socket = Celluloid::ZMQ::PushSocket.new
      begin
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

    def push_request(request)
      send_message request
      save_request request
      response = receive(@heartbeat_timeout*2) do |msg|
        msg.respond_to?(:request_id) && msg.request_id == request.id
      end
      delete_request request
      response
    end

    def dead_actor
      raise ::Celluloid::DeadActorError.new
    end

    def handle_response(request, response)
      unless response
        dead_actor if request.kind_of? Message::Relay
        return false
      end
      return false if response.is_a? RetryResponse
      dead_actor if response.is_a? DeadActorResponse
      if response.is_a? ErrorResponse
        klass = Utils::full_const_get response.value[:class]
        msg = response.value[:msg]
        raise klass.new msg
      end
      true
    end

    def send_request(request)
      # FIXME: need a robust way to retry the lost requests
      loop do
        response = push_request request
        if handle_response request, response
          return response.value
        end
      end
    end

    # Find an call registered with a given name on this node
    def find(name)
      request = Message::Find.new(Thread.mailbox, name)
      mailbox, methods = send_request request
      return nil if mailbox.kind_of? NilClass
      actor = DCell::ActorProxy.new self, mailbox, methods
      add_actor actor
      actor
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

    # Relay message to remote actor
    def relay(message)
      request = Message::Relay.new(Thread.mailbox, message)
      send_request request
    end

    # Send a message to another DCell node
    def send_message(message)
      begin
        message = message.to_msgpack
      rescue => e
        abort e
      end
      socket << message
    end
    alias_method :<<, :send_message
    
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
      transition :partitioned, :delay => @heartbeat_timeout
    end

    # Friendlier inspection
    def inspect
      "#<DCell::Node[#{@id}] @addr=#{@addr.inspect}>"
    end
  end
end
