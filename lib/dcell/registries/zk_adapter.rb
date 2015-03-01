require 'zk'

module DCell
  module Registry
    class ZkAdapter
      include Node
      include Global

      PREFIX  = "/dcell"
      DEFAULT_PORT = 2181

      # Create a new connection to Zookeeper
      #
      # servers: a list of Zookeeper servers to connect to. Each server in the
      #          list has a host/port configuration
      def initialize(options)
        options = Utils::symbolize_keys options

        @env = options[:env] || 'production'
        @base_path = "#{PREFIX}/#{@env}"

        # Let them specify a single server instead of many
        server = options[:server]
        if server
          servers = [server]
        else
          servers = options[:servers]
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
        @node_registry = Registry.new(@zk, @base_path, :nodes, true)
        @global_registry = Registry.new(@zk, @base_path, :globals, false)
      end

      class Registry
        def initialize(zk, base_path, name, ephemeral)
          @zk = zk
          @base_path = File.join(base_path, name.to_s)
          @ephemeral = ephemeral
          @zk.mkdir_p @base_path
        end

        def get(key)
          result, _ = @zk.get("#{@base_path}/#{key}", watch: true)
          MessagePack.unpack(result, options={symbolize_keys: true}) if result
        rescue ZK::Exceptions::NoNode
        end

        def _set(key, value, unique)
          path = "#{@base_path}/#{key}"
          @zk.create path, value.to_msgpack, ephemeral: @ephemeral
        rescue ZK::Exceptions::NodeExists
          raise KeyExists if unique
          @zk.set path, value.to_msgpack
        end

        def set(key, value)
          _set(key, value, false)
        end

        def all
          @zk.children @base_path
        end

        def remove(key)
          path = "#{@base_path}/#{key}"
          @zk.delete path
        rescue ZK::Exceptions::NoNode
        end

        def clear_all
          all.each do |key|
            remove key
          end
          @zk.rm_rf @base_path
          @zk.mkdir_p @base_path
        end
      end
    end
  end
end
