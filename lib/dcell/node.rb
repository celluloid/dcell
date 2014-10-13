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
      Celluloid::Logger.info "Connected to #{id}"
    end
    state :partitioned do
      Celluloid::Logger.warn "Communication with #{id} interrupted"
    end
    
    @nodes = {}
    @lock  = Mutex.new

    @heartbeat_rate    = 5  # How often to send heartbeats in seconds
    @heartbeat_timeout = 10 # How soon until a lost heartbeat triggers a node partition

    # Singleton methods
    class << self
      include Enumerable
      extend Forwardable

      def_delegators "Celluloid::Actor[:node_manager]", :all, :each, :find, :[], :remove, :update
      def_delegators "Celluloid::Actor[:node_manager]", :heartbeat_rate, :heartbeat_timeout
    end

    def initialize(id, addr)
      @id, @addr = id, addr
      @socket = nil
      @heartbeat = nil

      # Total hax to accommodate the new Celluloid::FSM API
      attach self
    end

    def update_address( addr )
      @addr = addr
      send_heartbeat
    end

    def shutdown
      transition :shutdown
      @socket.close if @socket
    end

    # Obtain the node's 0MQ socket
    def socket
      return @socket if @socket

      @socket = Celluloid::ZMQ::PushSocket.new
      begin
        @socket.connect addr
      rescue IOError
        @socket.close
        @socket = nil
        raise
      end

      transition :connected
      @socket
    end

    # Find an actor registered with a given name on this node
    def find(name)
      request = Message::Find.new(Thread.mailbox, name)
      send_message request

      response = receive do |msg|
        msg.respond_to?(:request_id) && msg.request_id == request.id
      end

      abort response.value if response.is_a? ErrorResponse
      response.value
    end
    alias_method :[], :find

    # List all registered actors on this node
    def actors
      request = Message::List.new(Thread.mailbox)
      send_message request

      response = receive do |msg|
        msg.respond_to?(:request_id) && msg.request_id == request.id
      end

      abort response.value if response.is_a? ErrorResponse
      response.value
    end
    alias_method :all, :actors

    # Send a message to another DCell node
    def send_message(message)
      begin
        message = Marshal.dump(message)
      rescue => ex
        abort ex
      end

      socket << message
    end
    alias_method :<<, :send_message
    
    # Send a heartbeat message after the given interval
    def send_heartbeat
      send_message DCell::Message::Heartbeat.new
      @heartbeat = after(self.class.heartbeat_rate) { send_heartbeat }
    end

    # Handle an incoming heartbeat for this node
    def handle_heartbeat
      transition :connected
      transition :partitioned, :delay => self.class.heartbeat_timeout
    end

    # Friendlier inspection
    def inspect
      "#<DCell::Node[#{@id}] @addr=#{@addr.inspect}>"
    end
  end
end
