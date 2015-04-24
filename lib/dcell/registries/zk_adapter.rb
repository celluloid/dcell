require "zk"

module DCell
  module Registry
    class ZkAdapter
      include Node
      include Global

      # Create a new connection to Zookeeper
      #
      # servers: a list of Zookeeper servers to connect to. Each server in the
      #          list has a host/port configuration
      def initialize(options={})
        options = Utils.symbolize_keys options

        env = options[:env] || "production"
        base_path = options[:namespace] || "/dcell/#{env}"

        options[:servers] ||= []
        options[:servers] << "127.0.0.1:2181" unless options[:servers].any?

        @zk = ZK.new(*options[:servers])
        @node_registry = Registry.new(@zk, base_path, :nodes)
        @global_registry = Registry.new(@zk, base_path, :globals)
      end

      class Registry
        include Celluloid

        finalizer :close

        def initialize(zk, base_path, name)
          @zk = zk
          @base_path = File.join(base_path, name.to_s)
          @zk.mkdir_p @base_path
        end

        def close
          @zk.close!
        end

        def get(key)
          result, _ = @zk.get("#{@base_path}/#{key}", watch: true)
          MessagePack.unpack(result, symbolize_keys: true) if result
        rescue ZK::Exceptions::NoNode
        end

        def _set(key, value, unique)
          path = "#{@base_path}/#{key}"
          @zk.create path, value.to_msgpack
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
          closed = @zk.closed?
          @zk.reopen if closed
          path = "#{@base_path}/#{key}"
          @zk.delete path
        rescue ZK::Exceptions::NoNode
        ensure
          @zk.close if closed
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
