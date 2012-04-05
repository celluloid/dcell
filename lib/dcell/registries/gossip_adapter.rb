require 'forwardable'

module DCell
  module Registry
    class GossipAdapter
      extend Forwardable
      PREFIX = "/dcell"

      def_delegator :@node_registry, :[],    :get_node
      def_delegator :@node_registry, :[]=,   :set_node
      def_delegator :@node_registry, :clear, :clear_nodes
      def_delegator :@node_registry, :keys,  :nodes

      def_delegator  :@global_registry, :get,     :get_global
      def_delegator  :@global_registry, :set,     :set_global
      def_delegator  :@global_registry, :clear,   :clear_globals
      def_delegator  :@global_registry, :keys,    :global_keys
      def_delegators :@global_registry, :changed, :observe, :values

      def initialize(options)
        # Convert all options to symbols :/
        options = options.inject({}) { |h,(k,v)| h[k.to_sym] = v; h }

        @env = options[:env] || 'production'
        @base_path = options[:namespace] || "#{PREFIX}/#{@env}"

        @node_registry   = {}
        @global_registry = Gossip::Store.new("#{@base_path}/globals")
      end
    end
  end
end
