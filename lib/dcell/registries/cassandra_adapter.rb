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

        @node_registry   = NodeRegistry.new(cass, columnfamily)
        @global_registry = GlobalRegistry.new(cass, columnfamily)
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
        def initialize(cass, cf)
          @cass = cass
          @cf = cf
        end

        def get(node_id)
          @cass.get @cf, "nodes", node_id
        end

        def set(node_id, addr)
          @cass.insert @cf, "nodes", { node_id => addr }
        end

        def nodes
          @cass.get(@cf, "nodes").keys
        end

        def remove(node_id)
          @cass.remove @cf, "nodes", node_id
        end

        def clear_all
          @cass.remove @cf, "nodes"
        end
      end

      def get_node(node_id);       @node_registry.get(node_id) end
      def set_node(node_id, addr); @node_registry.set(node_id, addr) end
      def nodes;                   @node_registry.nodes end

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

        def clear_all
          @cass.remove @cf, "globals"
        end
      end

      def get_global(key);        @global_registry.get(key) end
      def set_global(key, value); @global_registry.set(key, value) end
      def global_keys;            @global_registry.global_keys end
    end
  end
end
