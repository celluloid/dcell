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
        @node_registry = Registry.new(@zk, @base_path, :nodes, true)
        @global_registry = Registry.new(@zk, @base_path, :globals, false)
      end

      class Registry
        def initialize(zk, base_path, name, ephemeral)
          @zk = zk
          @base_path = File.join(base_path, name.to_s)
          @ephemeral = ephemeral
          @zk.mkdir_p @base_path
          @events = {}
        end

        def register(key)
          path = "#{@base_path}/#{key}"
          @events[path] ||= @zk.register(path) do |event|
            key = event.path.match(/#{@base_path}\/(\w+)/)[1]
            @events[event.path].unsubscribe
            @events[event.path] = nil
            if event.node_changed?
              Celluloid::logger.debug "zk callback: node changed!"
              Node.update(key)
            end
            if event.node_deleted?
              Celluloid::logger.debug "zk callback: node deleted!"
              Node.remove(key)
            end

          end
        end

        def get(key)
          register(key)
          result, _ = @zk.get("#{@base_path}/#{key}", watch: true)
          Marshal.load result
        rescue ZK::Exceptions::NoNode
        end

        def set(key, value)
          register(key)
          path = "#{@base_path}/#{key}"
          string = Marshal.dump value
          @zk.set path, string
        rescue ZK::Exceptions::NoNode
          @zk.create path, string, :ephemeral => @ephemeral
        end

        def all
          @zk.children @base_path
        end

        def clear
          # delete znodes so any registered
          # callback is triggered
          all.each do |key|
            path = "#{@base_path}/#{key}"
            @zk.delete path
          end
          @events.values.compact.each(&:unsubscribe)
          @events.clear
          @zk.rm_rf @base_path
          @zk.mkdir_p @base_path
        end
      end

      def get_node(node_id);       @node_registry.get(node_id) end
      def set_node(node_id, addr); @node_registry.set(node_id, addr) end
      def nodes;                   @node_registry.all end
      def clear_nodes;             @node_registry.clear end

      def get_global(key);        @global_registry.get(key) end
      def set_global(key, value); @global_registry.set(key, value) end
      def global_keys;            @global_registry.all end
      def clear_globals;          @global_registry.clear end

    end
  end
end
