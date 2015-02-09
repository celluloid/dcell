module DCell
  # Node metadata helper
  class DirectoryMeta
    attr_reader :id, :address, :actors

    def initialize(id, meta)
      @id = id
      if meta
        @address = meta[:address]
        @actors = meta[:actors].map {|a| a.to_sym}
      else
        @actors = Array.new
      end
    end

    def address=(address)
      @address = address
      DCell.registry.set_node @id, self
    end

    def actors=(actors)
      @actors = actors.map {|a| a.to_sym}
      DCell.registry.set_node @id, self
    end

    def add_actor(actor)
      @actors << actor.to_sym
      DCell.registry.set_node @id, self
    end
    alias_method :<<, :add_actor

    def to_msgpack(pk=nil)
      {
        :address => @address,
        :actors => @actors,
      }.to_msgpack(pk)
    end
  end

  # Directory of nodes connected to the DCell cluster
  module Directory
    include Enumerable
    extend self

    # Get the address for a particular Node ID
    def find(id)
      meta = DCell.registry.get_node(id)
      DirectoryMeta.new(id, meta)
    end
    alias_method :[], :find

    # List all of the node IDs in the directory
    def all
      DCell.registry.nodes
    end

    # Iterates over all registered nodes
    def each
      DCell.registry.nodes.each do |id|
        yield Directory[id]
      end
    end

    # Remove all nodes in the directory
    def clear_all
      DCell.registry.clear_all_nodes
    end

    # Remove information for a give Node ID
    def remove(id)
      DCell.registry.remove_node id
    end
  end
end
