require 'celluloid/redis'
require 'redis/connection/celluloid'
require 'redis-namespace'

module DCell
  module Registry
    class RedisAdapter
      include Node
      include Global

      def initialize(options)
        # Convert all options to symbols :/
        options = options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }

        @env = options[:env] || 'production'
        @namespace = options[:namespace] || "dcell_#{@env}"

        redis  = Redis.new options
        @redis = Redis::Namespace.new @namespace, :redis => redis

        @node_registry = Registry.new(@redis, 'nodes')
        @global_registry = Registry.new(@redis, 'globals')
      end

      class Registry
        def initialize(redis, table)
          @redis = redis
          @table = table
        end

        def get(key)
          value = @redis.hget @table, key.to_s
          value = MessagePack.unpack(value, options={:symbolize_keys => true}) if value
          value
        end

        def set(key, value)
          @redis.hset @table, key.to_s, value.to_msgpack
        end

        def all
          @redis.hkeys @table
        end

        def remove(key)
          @redis.hdel @table, key
        end

        def clear_all
          @redis.del @table
        end
      end
    end
  end
end
