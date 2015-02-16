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
              node = Node.new id, addr
            end
          rescue ResourceManagerConflict => e
            Logger.warn "Conflict on registering node #{id}"
            node.terminate
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

      def each(*args, &block)
        @nodes.each *args, &block
      end
    end
  end

  # Node lookup
  module NodeManager
    # Return all available nodes in the cluster
    def all
      Directory.all.map do |id|
        find id
      end
    end

    # Iterate across all available nodes
    def each
      Directory.all.each do |id|
        yield find id
      end
    end

    # Find a node by its node ID
    def find(id)
      NodeCache.register id
    end
    alias_method :[], :find
  end
end
