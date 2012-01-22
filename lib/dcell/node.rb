module DCell
  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM
    attr_reader :id, :addr

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

    # Ivars
    @nodes = {}
    @lock  = Mutex.new

    @heartbeat_rate    = 5  # How often to send heartbeats in seconds
    @heartbeat_timeout = 10 # How soon until a lost heartbeat triggers a node partition

    # Singleton methods
    class << self
      include Enumerable
      attr_reader :heartbeat_rate, :heartbeat_timeout

      # Return all available nodes in the cluster
      def all
        Directory.all.map do |node_id|
          find node_id
        end
      end

      # Iterate across all available nodes
      def each
        Directory.all.each do |node_id|
          yield find node_id
        end
      end

      # Find a node by its node ID
      def find(id)
        node = @lock.synchronize { @nodes[id] }
        return node if node

        addr = Directory[id]

        if addr
          if id == DCell.id
            node = DCell.me
          else
            node = Node.new(id, addr)
          end

          @lock.synchronize do
            @nodes[id] ||= node
            @nodes[id]
          end
        end
      end
      alias_method :[], :find
    end

    def initialize(id, addr)
      @id, @addr = id, addr
      @socket = nil
      @heartbeat = nil

      # Total hax to accommodate the new Celluloid::FSM API
      attach self
    end

    def finalize
      transition :shutdown
      @socket.close if socket
    end

    # Obtain the node's 0MQ socket
    def socket
      return @socket if @socket

      @socket = DCell.zmq_context.socket(::ZMQ::PUSH)
      unless ::ZMQ::Util.resultcode_ok? @socket.connect @addr
        @socket.close
        @socket = nil
        raise "error connecting to #{addr}: #{::ZMQ::Util.error_string}"
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
        string = Marshal.dump(message)
      rescue => ex
        abort ex
      end

      if ::ZMQ::Util.resultcode_ok? socket.send_string string
        # Ideally we could reset the heartbeat counter now because we've sent
        # a message. Heartbeats could work off all messages rather than just
        # DCell::Message::Heartbeat. Unfortunately this functionality is not
        # yet implemented, sorry!
        # @heartbeat.reset
      else
        raise "error sending 0MQ message: #{::ZMQ::Util.error_string}"
      end
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
