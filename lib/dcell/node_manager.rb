module DCell
  # Node discovery
  class NodeCache
    include Enumerable

    @nodes = ResourceManager.new

    class << self
      # Finds a node by its node ID and adds to the cache
      def find(id)
        return DCell.me if id == DCell.id

        @nodes.register(id) do
          addr = Directory[id]
          return nil unless addr
          Node.new id, addr
        end
      end
      alias_method :[], :find

      def delete(id)
        @nodes.delete id
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
      NodeCache.find id
    end
    alias_method :[], :find
  end
end
