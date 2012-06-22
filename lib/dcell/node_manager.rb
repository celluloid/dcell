module DCell
  # Manage nodes we're connected to
  class NodeManager
    include Celluloid::ZMQ

    attr_reader :gossip_rate, :heartbeat_timeout

    def initialize
      @timestamp = 0
      @gossip_rate       = 5  # How often to send gossip in seconds
      @heartbeat_timeout = 10 # How soon until a lost heartbeat triggers a node partition
      Directory.each { |node| node.socket if node } # Connect all so we can gossip
      @peers = Hash.new do |h,node|
        h[node.id] = Peer.new(node, @heartbeat_timeout)
      end
      @gossip = after(gossip_rate) { gossip_timeout }
    end

    # Send gossip to a random node (except ourself) after the given interval
    def gossip_timeout
      Celluloid::Logger.info "gossip"
      if peer = random_peer
        registry_data = nil
        # registry should register with manager
        if DCell.registry.is_a? Registry::GossipAdapter
          registry_data = peer.fresh? ? DCell.registry.values : DCell.registry.changed
        end
        @timestamp += 1

        peer.gossip(peer_data, registry_data)
      end
      @gossip = after(gossip_rate) { gossip_timeout }
    end

    def handle_gossip(peer_data, registry_data)
      peer_data.each do |id,addr,timestamp|
        node = Node.find(id)
        next if node.id == DCell.id
        @peers[id].handle_timestamp!(timestamp)
      end
      if DCell.registry.is_a? Registry::GossipAdapter
        data.map { |data| DCell.registry.observe data } if data
      end
    end

    def random_peer
      @peers.values.select { |node| peer.state == :connected }.sample(1)[0]
    end

    def peer_data
      @peers.inject({}) do |a,n|
        a[n.id] = {
          :addr => n.addr,
          :timestamp => n.timestamp,
        }
        a
      end
    end

    class Peer
      extend Forwardable

      def initialize(node, heartbeat_timeout)
        @node = node
        @timestamp = timestamp
        @heartbeat_timeout = heartbeat_timeout
        @fresh = true
      end
      attr_reader :timestamp

      def_delegators :@node, :id, :addr, :state

      def gossip(nodes, data)
        @node.send_message DCell::Message::Gossip.new nodes, data
      end

      # Handle an incoming timestamp observation for this node
      def handle_timestamp(t)
        @fresh = false if t > 0
        if @timestamp < t
          @timestamp = t
          @node.transition :connected
          after(@heartbeat_timeout) do
            Celluloid::Logger.warn "Communication with #{id} interrupted"
          end
          # is this always true?
          unless state == :connected
            Celluloid::Logger.info "Revived node #{id}"
          end
        end
      end

      def fresh?
        @fresh
      end
    end
  end
end
