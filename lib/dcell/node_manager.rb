module DCell
  # Manage nodes we're connected to
  class NodeManager
    include Celluloid
    include Enumerable

    trap_exit :node_died

    def initialize
      @nodes = {}
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
        self.link node
      end

      @nodes[id] ||= node
      # This code is racy, kind of w/a
      if node != @nodes[id]
        node.terminate
      end
      @nodes[id]
    end
    alias_method :[], :find

    def node_died(node, reason)
      if reason.nil? # wtf?
        # this wtf error seems to come from node socket writes
        # when the socket is not reachable anymore
        Celluloid::logger.debug "wtf?"
        return
      end
      # Handle dead node???
    end
  end
end
