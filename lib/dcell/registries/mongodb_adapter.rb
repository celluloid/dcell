require 'mongoid'

module DCell
  module Registry
    class MongodbAdapter
      # Setup connection to mongodb
      # config: path to mongoid configuration file
      # env: mongoid environment to use
      def initialize(options)
        if options[:config]
          Mongoid.load! options[:config], options[:env]
        elsif options[:db]
          Mongoid.connect_to options[:db]
        end
        if options[:options]
          Mongoid.options = options[:options]
        end
      end

      class DCellNode
        include Mongoid::Document

        field :key, type: String
        field :value, type: Hash
      end

      class DCellGlobal
        include Mongoid::Document

        field :key, type: String
        field :value, type: Hash
      end

      class Proxy
        class << self
          def set(storage, key, value)
            entry = storage.find_or_create_by(key: key)
            entry.value = {'v' => value}
            entry.save!
            value
          end

          def get(storage, key)
            storage.where(key: key).first.value['v']
          end

          def all(storage)
            keys = []
            storage.each do |entry|
              keys << entry.key
            end
            keys
          end

          def clear(storage)
            storage.delete_all
          end
        end
      end

      def get_node(node_id);       Proxy.get(DCellNode, node_id) end
      def set_node(node_id, addr); Proxy.set(DCellNode, node_id, addr) end
      def nodes;                   Proxy.all(DCellNode) end
      def clear_nodes;             Proxy.clear(DCellNode) end

      def get_global(key);         Proxy.get(DCellGlobal, key) end
      def set_global(key, value);  Proxy.set(DCellGlobal, key, value) end
      def global_keys;             Proxy.all(DCellGlobal) end
      def clear_globals;           Proxy.clear(DCellGlobal) end

    end
  end
end
