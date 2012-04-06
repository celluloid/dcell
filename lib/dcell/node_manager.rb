module DCell
  # Manage nodes we're connected to
  class NodeManager
    include Celluloid::ZMQ
    include Enumerable

    attr_reader :heartbeat_rate, :heartbeat_timeout

    def initialize
      @nodes = {}

      @heartbeat_rate    = 5  # How often to send heartbeats in seconds
      @heartbeat_timeout = 10 # How soon until a lost heartbeat triggers a node partition
    end

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
      node = @nodes[id]
      return node if node

      addr = Directory[id]
      return unless addr

      if id == DCell.id
        node = DCell.me
      else
        node = Node.new(id, addr)
      end

      @nodes[id] ||= node
      @nodes[id]
    end
    alias_method :[], :find
  end
end
