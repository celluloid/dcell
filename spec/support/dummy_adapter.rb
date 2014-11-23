module DCell::Registry
  class DummyAdapter
    def initialize(options)
      @options = options
      @nodes = {}
    end

    def set_node(node, addr)
      @nodes[node] = addr
    end

    def unique
      @options[:seed]
    end
  end

  class NoopAdapter
    def initialize(options)
    end
  end
end
