module DCell
  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM
    attr_reader :id, :addr, :timestamp

    # FSM
    default_state :disconnected
    state :shutdown
    state :disconnected, :to => [:connected, :shutdown]
    state :connected do
      Celluloid::Logger.info "Connected to #{id}"
    end
    state :partitioned do
      Celluloid::Logger.warn "Communication with #{id} interrupted"
    end

    # Singleton methods
    class << self
      include Enumerable
      extend Forwardable

      #def_delegators "Celluloid::Actor[:node_manager]", :handle_gossip, :gossip_rate, :heartbeat_timeout
      def_delegators Directory, :all, :each, :get, :[]
    end

    def initialize(id, addr)
      @id, @addr = id, addr
      @timestamp = 0
      @socket = nil
      @fresh = true

      # Total hax to accommodate the new Celluloid::FSM API
      attach self
    end

    def finalize
      transition :shutdown
      @gossip.cancel if @gossip
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

    def tick
      @timestamp += 1
    end

    def fresh?
      @fresh
    end

    # Handle an incoming timestamp observation for this node
    def handle_timestamp(t)
      @fresh = false if t > 0
      if @timestamp < t
        @timestamp = t
        transition :connected
        transition :partitioned, :delay => self.class.heartbeat_timeout
        unless state == :connected
          Celluloid::Logger.info "Revived node #{id}"
        end
      end
    end

    # Friendlier inspection
    def inspect
      "#<DCell::Node[#{@id}] @addr=#{@addr.inspect}>"
    end
  end
end
