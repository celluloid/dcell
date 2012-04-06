require 'cassandra'

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
      DEFAULT_KEYSPACE = "dcell"
      DEFAULT_CF = "dcell"

      def initialize(options)
        # Convert all options to symbols :/
        options = options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }

        keyspace = options[:keyspace] || DEFAULT_KEYSPACE
        columnfamily = options[:columnfamily] || DEFAULT_CF

        options[:servers] ||= []
        options[:servers] << options[:server] if options[:server]
        options[:servers] << "localhost:9160" unless options[:servers].any?

        cass = Cassandra.new(keyspace, options[:servers])

        @global_registry = GlobalRegistry.new(cass, columnfamily)
      end

      def clear_globals
        @global_registry.clear
      end

      class GlobalRegistry
        def initialize(cass, cf)
          @cass = cass
          @cf = cf
        end

        def get(key)
          string = @cass.get @cf, "globals", key.to_s
          Marshal.load string if string
        end

        # Set a global value
        def set(key, value)
          string = Marshal.dump value
          @cass.insert @cf, "globals", { key.to_s => string }
        end

        # The keys to all globals in the system
        def global_keys
          @cass.get(@cf, "globals").keys
        end

        def clear
          @cass.del @cf, "globals"
        end
      end

      def get_global(key);        @global_registry.get(key) end
      def set_global(key, value); @global_registry.set(key, value) end
      def global_keys;            @global_registry.global_keys end
    end
  end
end
