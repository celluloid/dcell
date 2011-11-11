module DCell
  # Directory of nodes connected to the DCell cluster
  class Directory
    class RequestError < StandardError; end # The directory couldn't process the given request

    class << self
      # Configure the directory system with the given options
      #
      # * adapter: zk (the only acceptable option now is Zookeper)
      # * servers: address of the Zookeper servers to connect to
      def setup(options)
        adapter_type = options[:adapter] || options['adapter'] || 'zk'
        raise "only acceptable directory adapter is 'zk'" unless adapter_type == "zk"

        @adapter = ZookeeperAdapter.new(options)
      end

      # Get the URL for a particular Node ID
      def get(node_id)
        assert_configured
        @adapter.get_node node_id
      end
      alias_method :[], :get

      # Set the address of a particular Node ID
      def set(node_id, addr)
        assert_configured
        @adapter.set_node node_id, addr
      end
      alias_method :[]=, :set

      def assert_configured
        raise RequestError, "please run DCell::Directory.setup" unless @adapter
      end
    end
  end
end
