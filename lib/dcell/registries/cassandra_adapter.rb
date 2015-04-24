require "cassandra"

# create the keyspace / columnfamily with cqlsh
#
# create keyspace dcell
#  with strategy_class='SimpleStrategy'
#   and strategy_options:replication_factor=3;
#
# create columnfamily dcell (dcell_type ascii primary key);

# not sure this is right yet ...
# Keyspace "whatever" [
#   ColumnFamily "dcell" {
#     RowKey "nodes": {
#       <nodeid>: <address>,
#       <nodeid>: <address>,
#       ...
#     }
#     RowKey "globals": {
#       <key>: <marshal blob>,
#       <key>: <marshal blob>,
#       ...
#     }
#   }
# ]
#

module DCell
  module Registry
    class CassandraAdapter
      include Node
      include Global

      def initialize(options={})
        options = Utils.symbolize_keys options

        keyspace = options[:env] || "production"
        columnfamily = options[:namespace] || "dcell"

        cass = Cassandra.new(keyspace, servers(options))

        @node_registry = Registry.new(cass, "nodes", columnfamily)
        @global_registry = Registry.new(cass, "globals", columnfamily)
      end

      def servers(options)
        servers = options[:servers] || []
        servers << options[:server] if options[:server]
        servers << "127.0.0.1:9160" unless servers.any?
        servers
      end

      class Registry
        def initialize(cass, table, cf)
          @cass = cass
          @table = table
          @cf = cf
        end

        def get(key)
          value = @cass.get @cf, @table, key.to_s
          return nil unless value
          MessagePack.unpack(value, symbolize_keys: true)
        end

        def set(key, value)
          @cass.insert @cf, @table, key.to_s => value.to_msgpack
        end

        def all
          @cass.get(@cf, @table).keys
        end

        def remove(key)
          @cass.remove @cf, @table, key
        end

        def clear_all
          @cass.remove @cf, @table
        end
      end
    end
  end
end
