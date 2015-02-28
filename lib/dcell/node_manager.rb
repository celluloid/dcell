module DCell
  # Node discovery
  class NodeCache
    @nodes = ResourceManager.new

    class << self
      # Finds a node by its node ID and adds to the cache
      def register(id, addr)
        return DCell.me if id == DCell.id
        return nil unless addr
        loop do
          begin
            node = nil
            return @nodes.register(id) do
              node = Node.new(id, addr) rescue nil
            end
          rescue ResourceManagerConflict => e
            Logger.warn "Conflict on registering node #{id}"
            node.detach
            next
          end
        end
      end

      def find(id)
        @nodes.find id
      end

      def delete(id)
        @nodes.delete id
      end
    end
  end

  # Node lookup
  module NodeManager
    # Iterate across all available nodes
    def each
      Directory.each do |node|
        # skip dead nodes and nodes w/o an address, those might not be operational yet
        next unless node.alive? and node.address
        remote = NodeCache.register node.id, node.address
        yield remote
      end
    end

    # Find a node by its node ID
    def find(id)
      node = Directory[id]
      return nil unless node.alive? and node.address
      NodeCache.register id, node.address
    end
    alias_method :[], :find
  end
end
