module DCell
  # Node discovery
  class NodeCache
    @nodes = ResourceManager.new

    class << self
      # Finds a node by its node ID and adds to the cache
      def register(id)
        return DCell.me if id == DCell.id
        addr = Directory[id].address
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
        remote = find node.id
        yield remote
      end
    end

    # Find a node by its node ID
    def find(id)
      NodeCache.register id
    end
    alias_method :[], :find
  end
end
