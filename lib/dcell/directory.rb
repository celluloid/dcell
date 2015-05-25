module DCell
  # Node metadata helper
  class DirectoryMeta
    attr_reader :id, :address, :actors, :ttl, :pubkey

    def initialize(id, meta)
      @id = id
      if meta
        @address = meta[:address]
        @actors = meta[:actors].map(&:to_sym)
        @ttl = Time.at meta[:ttl] || 0
        @pubkey = meta[:pubkey]
      else
        @address = nil
        @actors = []
        @ttl = Time.now
        @pubkey = nil
      end
    end

    def address=(address)
      @address = address
      DCell.registry.set_node @id, self
    end

    def pubkey=(pubkey)
      @pubkey = pubkey
      DCell.registry.set_node @id, self
    end

    def actors=(actors)
      @actors = actors.map(&:to_sym)
      DCell.registry.set_node @id, self
    end

    def add_actor(actor)
      @actors << actor.to_sym
      DCell.registry.set_node @id, self
    end
    alias_method :<<, :add_actor

    def update_ttl(time=nil)
      @ttl = time || Time.now
      DCell.registry.set_node @id, self
    end

    def alive?
      Time.now - @ttl < DCell.ttl_rate * 2
    end

    def to_msgpack(pk=nil)
      {
        address: @address,
        actors: @actors,
        ttl: @ttl.to_i,
        pubkey: @pubkey,
      }.to_msgpack(pk)
    end
  end

  # Directory of nodes connected to the DCell cluster
  module Directory
    include Enumerable
    extend self

    # Get the address for a particular Node ID
    def find(id)
      return nil unless id
      meta = DCell.registry.get_node(id)
      DirectoryMeta.new(id, meta)
    end
    alias_method :[], :find

    # Iterates over all registered nodes
    def each
      DCell.registry.nodes.each do |id|
        yield id
      end
    end

    # Remove all nodes in the directory
    def clear_all
      # :nocov:
      DCell.registry.clear_all_nodes
      # :nocov:
    end

    # Remove information for a give Node ID
    def remove(id)
      DCell.registry.remove_node id
    end
  end
end
