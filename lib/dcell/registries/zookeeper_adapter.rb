require 'zk'

module DCell
  class ZookeeperAdapter
    PREFIX  = "/dcell"
    DEFAULT_PORT = 2181

    # Create a new connection to Zookeeper
    #
    # servers: a list of Zookeeper servers to connect to. Each server in the
    #          list has a host/port configuration
    def initialize(options)
      # Stringify keys :/
      options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

      @env = options['env'] || 'production'
      @base_path = "#{PREFIX}/#{@env}"

      # Let them specify a single server instead of many
      server = options['server']
      if server
        servers = [server]
      else
        servers = options['servers']
        raise "no Zookeeper servers given" unless servers
      end

      # Add the default Zookeeper port unless specified
      servers.map! do |server|
        if server[/:\d+$/]
          server
        else
          "#{server}:#{DEFAULT_PORT}"
        end
      end

      @zk = ZK.new(*servers)
      @node_registry = NodeRegistry.new(@zk, @base_path)
      @global_registry = GlobalRegistry.new(@zk, @base_path)
    end

    class NodeRegistry
      def initialize(zk, base_path)
        @zk, @base_path = zk, "#{base_path}/nodes"
        @zk.mkdir_p @base_path
      end

      def get(node_id)
        result, _ = @zk.get("#{@base_path}/#{node_id}")
        result
      rescue ZK::Exceptions::NoNode
      end

      def set(node_id, addr)
        path = "#{@base_path}/#{node_id}"
        @zk.set path, addr
      rescue ZK::Exceptions::NoNode
        @zk.create path, addr
      end

      def nodes
        @zk.children @base_path
      end
    end

    def get_node(node_id);       @node_registry.get(node_id) end
    def set_node(node_id, addr); @node_registry.set(node_id, addr) end
    def nodes;                   @node_registry.nodes end

    class GlobalRegistry
      def initialize(zk, base_path)
        @zk, @base_path = zk, "#{base_path}/globals"
        @zk.mkdir_p @base_path
      end

      def get(key)
        value, _ = @zk.get "#{@base_path}/#{key}"
        Marshal.load value
      rescue ZK::Exceptions::NoNode
      end

      # Set a global value
      def set(key, value)
        path = "#{@base_path}/#{key}"
        string = Marshal.dump value

        @zk.set path, string
      rescue ZK::Exceptions::NoNode
        @zk.create path, string
      end

      # The keys to all globals in the system
      def global_keys
        @zk.children(@base_path).map(&:to_sym)
      end
    end

    def get_global(key);        @global_registry.get(key) end
    def set_global(key, value); @global_registry.set(key, value) end
    def global_keys;            @global_registry.global_keys end
  end
end
