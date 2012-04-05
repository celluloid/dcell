module DCell
  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM
    attr_reader :id, :addr
    attr_accessor :timestamp, :fresh

    # FSM
    default_state :disconnected
    state :shutdown
    state :disconnected, :to => [:connected, :shutdown]
    state :connected do
      gossip_timeout if id == DCell.id
      Celluloid::Logger.info "Connected to #{id}"
    end
    state :partitioned do
      Celluloid::Logger.warn "Communication with #{id} interrupted"
    end

    # Ivars
    @nodes = {}
    @lock  = Mutex.new

    @gossip_rate       = 5  # How often to send gossip in seconds
    @heartbeat_timeout = 20 # How soon until a lost heartbeat triggers a node partition

    # Singleton methods
    class << self
      include Enumerable
      attr_reader :gossip_rate, :heartbeat_timeout

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
      @timestamp = 0
      @socket = nil
      @gossip = nil
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

    def gossip
      peers = Node.select { |node| node.state == :connected }
      peers = peers.inject([]) { |a,n| a << [n.id, n.addr, n.timestamp]; a } 
      data = @fresh ? DCell.registry.values : DCell.registry.changed
      send_message DCell::Message::Gossip.new id, peers, data
    end

    # Send gossip to a random node (except ourself) after the given interval
    def gossip_timeout
      @timestamp += 1
      peer = Node.select { |node| node.id != DCell.id }.sample(1)[0]
      peer.gossip if peer

      @gossip = after(self.class.gossip_rate) { gossip_timeout }
    end
    
    def handle_gossip(peers, data)
      peers.each do |id, addr, timestamp|
        if (node = Node.find(id))
          node.fresh = false if timestamp > 0
          if timestamp > node.timestamp
            node.timestamp = timestamp
            node.handle_heartbeat
            unless node.state == :connected
              Celluloid::Logger.info "Revived node #{id}"
            end
          end
        else
          Directory[id] = addr
          Celluloid::Logger.info "Found node #{id}"
        end
      end
      data.map { |data| DCell.registry.observe data }
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
