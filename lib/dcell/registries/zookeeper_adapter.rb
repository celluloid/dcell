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
      @env = options[:env] || options['env'] || 'production'

      # Let them specify a single server instead of many
      server = options[:server] || options['server']
      if server
        servers = [server]
      else
        servers = options[:servers] || options['servers']
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
      @zk.mkdir_p "#{base_path}/nodes"
    end

    # Get the address of a particular node
    def get_node(node_id)
      result, _ = @zk.get("#{base_path}/nodes/#{node_id}")
      result
    end

    # Set the address of a particular node
    def set_node(node_id, addr)
      path = "#{base_path}/nodes/#{node_id}"
      @zk.set path, addr
    rescue ZK::Exceptions::NoNode
      @zk.create path, addr
    end

    # Find all of the nodes on the system
    def nodes
      @zk.children "#{base_path}/nodes"
    end

    # Base path for all entries
    def base_path
      "#{PREFIX}/#{@env}"
    end
  end
end
