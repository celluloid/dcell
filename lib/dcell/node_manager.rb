module DCell
  # Node discovery
  class NodeCache
    @nodes = ResourceManager.new

    class << self
      include Enumerable

      def __register(id)
        @nodes.register(id) do
          ninfo = Directory[id]
          alive = ninfo && ninfo.alive? && ninfo.address
          Node.new(id, ninfo.address) if alive
        end
      rescue ResourceManagerConflict => e
        # :nocov:
        Logger.warn "Conflict on registering node #{id}"
        e.item.detach
        raise
        # :nocov:
      end

      # Finds a node by its node ID and adds to the cache
      def register(id)
        return DCell.me if id == DCell.id
        while true
          begin
            return __register id
          rescue ResourceManagerConflict
          end
        end
      end

      def each(&block)
        @nodes.each(&block)
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
      Directory.each do |id|
        remote = NodeCache.register id
        next unless remote
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
