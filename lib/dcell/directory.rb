module DCell
  # Directory of the connected DCell cluster
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
      def get(nodeid)
        assert_configured
        @adapter.get nodeid
      end
      alias_method :[], :get

      # Set the URL for a particular Node ID
      def set(nodeid, url)
        assert_configured
        @adapter.set nodeid, url
      end
      alias_method :[]=, :set

      def assert_configured
        raise RequestError, "please run DCell::Directory.setup" unless @adapter
      end
    end
  end
end
