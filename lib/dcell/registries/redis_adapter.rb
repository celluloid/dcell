require 'celluloid/redis'
require 'redis/connection/celluloid'
require 'redis-namespace'

module DCell
  module Registry
    class RedisAdapter
      def initialize(options)
        # Convert all options to symbols :/
        options = options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }

        @env = options[:env] || 'production'
        @namespace = options[:namespace] || "dcell_#{@env}"

        redis  = Redis.new options
        @redis = Redis::Namespace.new @namespace, :redis => redis

        @node_registry   = NodeRegistry.new(@redis)
        @global_registry = GlobalRegistry.new(@redis)
      end

      def remove_node(node)
        @node_registry.remove node
      end

      def clear_all_nodes
        @node_registry.clear_all
      end

      def clear_globals
        @global_registry.clear_all
      end

      class NodeRegistry
        def initialize(redis)
          @redis = redis
        end

        def get(node_id)
          @redis.hget 'nodes', node_id
        end

        def set(node_id, addr)
          @redis.hset 'nodes', node_id, addr
        end

        def nodes
          @redis.hkeys 'nodes'
        end

        def remove(node)
          @redis.hdel 'nodes', node
        end

        def clear_all
          @redis.del 'nodes'
        end
      end

      def get_node(node_id);       @node_registry.get(node_id) end
      def set_node(node_id, addr); @node_registry.set(node_id, addr) end
      def nodes;                   @node_registry.nodes end

      class GlobalRegistry
        def initialize(redis)
          @redis = redis
        end

        def get(key)
          string = @redis.hget 'globals', key.to_s
          MessagePack.unpack(string, options={:symbolize_keys => true}) if string
        end

        # Set a global value
        def set(key, value)
          @redis.hset 'globals', key.to_s, value.to_msgpack
        end

        # The keys to all globals in the system
        def global_keys
          @redis.hkeys 'globals'
        end

        def clear_all
          @redis.del 'globals'
        end
      end

      def get_global(key);        @global_registry.get(key) end
      def set_global(key, value); @global_registry.set(key, value) end
      def global_keys;            @global_registry.global_keys end
    end
  end
end
