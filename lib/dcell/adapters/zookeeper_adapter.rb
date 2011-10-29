require 'zookeeper'

module DCell
  class ZookeeperAdapter
    NODE_PREFIX  = "/dcell"
    DEFAULT_PORT = 2181

    # Create a new connection to Zookeeper
    #
    # servers: a list of Zookeeper servers to connect to. Each server in the
    #          list has a host/port configuration
    def initialize(options)
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

      begin
        @zk = Zookeeper.new(*servers)
      rescue ZookeeperExceptions::ZookeeperException::NotConnected, RuntimeError
        raise Directory::RequestError, "couldn't connect to the Zookeper server"
      end
    end

    # Get a particular key from Zookeeper
    def get(key)
      result = @zk.get(:path => "#{NODE_PREFIX}/#{key}")
      return unless zk_success? result
      result[:data]
    rescue ZookeeperExceptions::ZookeeperException::NotConnected
      raise Directory::RequestError, "couldn't connect to the Zookeper server"
    end

    # Set a value within Zookeeper
    def set(key, value)
      path = "#{NODE_PREFIX}/#{key}" # Path to the given directory node

      unless zk_success? @zk.set(:path => path, :data => value)
        create_node path

        # Retry the original request
        unless zk_success? @zk.set(:path => path, :data => value)
          raise "couldn't set a Zookeeper node's value"
        end
      end

      value
    rescue ZookeeperExceptions::ZookeeperException::NotConnected
      raise Directory::RequestError, "couldn't connect to the Zookeper server"
    end

    #######
    private
    #######

    # Create a Zookeeper node
    def create_node(path)
      # Attempt to create the given key if it doesn't already exist
      unless zk_success? @zk.create(:path => path)
        create_toplevel_node

        unless zk_success? @zk.create(:path => path)
          raise "couldn't create a Zookeeper node"
        end
      end
      true
    end

    # Create the toplevel Zookeeper node for DCell state
    def create_toplevel_node
      unless zk_success? @zk.create(:path => NODE_PREFIX)
        raise "unable to create toplevel node in Zookeeper"
      end
      true
    end

    # Was the given request to Zookeeper successful?
    def zk_success?(result)
      result[:rc] == 0
    end
  end
end
