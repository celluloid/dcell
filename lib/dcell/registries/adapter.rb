module DCell
  module Registry
    # A DCell registry must implement following methods:
    # - set(key, value): insert a key->value tuple, overrides previous entry if exists
    # - get(key): get a value for the key, returns nil if the key is not yet registered
    # - all: return all registered keys
    # - remove(key): remove an entry for the key
    # - clear_all: remove all entries
    #
    # DCell requires following independent registry namespaces:
    #  - node
    #  - global
    #
    # It's up to the registry backend how namespaces are implented(dedicated tables, databases, combinatation of ns:key, etc.)

    module Node
      def get_node(node_id)
        @node_registry.get(node_id)
      end

      def set_node(node_id, addr)
        @node_registry.set(node_id, addr)
      end

      def nodes
        @node_registry.all
      end

      def remove_node(node_id)
        @node_registry.remove(node_id)
      end

      def clear_all_nodes
        @node_registry.clear_all
      end
    end

    module Global
      def get_global(key)
        @global_registry.get(key)
      end

      def set_global(key, value)
        @global_registry.set(key, value)
      end

      def global_keys
        @global_registry.all
      end

      def clear_globals
        @global_registry.clear_all
      end
    end
  end
end
