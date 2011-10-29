require 'zookeeper'

module DCell
  class ZookeeperAdapter
    PREFIX = "/dcell"

    # Create a new connection to Zookeeper
    #
    # servers: a list of Zookeeper servers to connect to. Each server in the
    #          list has a host/port configuration
    def initialize(options)
      servers = options[:servers] || options['servers']
      raise "no Zookeeper servers given" unless servers

      addrs = []
      [servers].flatten.each do |server|
        host = server[:host] || server['host']
        next unless host

        port = server[:port] || server['port'] || 2181
        addrs << "#{host}:#{port}"
      end

      raise "no valid Zookeeper servers found!" if addrs.empty?
      @zk = Zookeeper.new(*addrs)
    rescue ZookeeperExceptions::ZookeeperException::NotConnected
      raise Directory::RequestError, "couldn't connect to the Zookeper server"
    end

    # Get a particular key from Zookeeper
    def get(key)
      result = @zk.get(:path => "#{PREFIX}/#{key}")
      return unless result[:rc] == 0
      result[:data]
    rescue ZookeeperExceptions::ZookeeperException::NotConnected
      raise Directory::RequestError, "couldn't connect to the Zookeper server"
    end

    # Set a value within Zookeeper
    def set(key, value)
      path = "#{PREFIX}/#{key}" # Path to the given directory node

      result = @zk.set :path => path, :data => value
      unless result[:rc] == 0
        create_node path

        # Retry the original request
        result = @zk.set :path => path, :data => value
        raise "couldn't set a Zookeeper node's value" unless result[:rc] == 0
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
      result = @zk.create :path => path
      unless result[:rc] == 0
        create_toplevel_node
        result = @zk.create :path => path
        raise "couldn't create a Zookeeper node" unless result[:rc] == 0
      end
      true
    end

    # Create the toplevel Zookeeper node for DCell state
    def create_toplevel_node
      result = @zk.create :path => PREFIX
      raise "unable to create toplevel node in Zookeeper" unless result[:rc] == 0
      true
    end
  end
end
