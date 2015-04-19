module DCell
  # Node discovery
  class NodeCache
    @nodes = ResourceManager.new

    class << self
      # Finds a node by its node ID and adds to the cache
      def register(id)
        return DCell.me if id == DCell.id
        loop do
          begin
            node = nil
            return @nodes.register(id) do
              ninfo = Directory[id]
              if ninfo && ninfo.alive? && ninfo.address
                node = Node.new(id, ninfo.address) rescue nil
              end
            end
          rescue ResourceManagerConflict
            # :nocov:
            Logger.warn "Conflict on registering node #{id}"
            node.detach
            next
            # :nocov:
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
