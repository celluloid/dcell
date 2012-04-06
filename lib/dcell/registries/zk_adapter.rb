require 'zk'

module DCell
  module Registry
    class ZkAdapter
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
        @global_registry = GlobalRegistry.new(@zk, @base_path)
      end

      def clear_globals
        @global_registry.clear
      end

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
          @zk.children(@base_path)
        end

        def clear
          @zk.rm_rf @base_path
          @zk.mkdir_p @base_path
        end
      end

      def get_global(key);        @global_registry.get(key) end
      def set_global(key, value); @global_registry.set(key, value) end
      def global_keys;            @global_registry.global_keys end
    end
  end
end
