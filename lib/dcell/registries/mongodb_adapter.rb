require 'mongoid'
require 'bson'

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
        field :value, type: BSON::Binary
      end

      class DCellGlobal
        include Mongoid::Document

        field :key, type: String
        field :value, type: BSON::Binary
      end

      class Proxy
        class << self
          def set(storage, key, value)
            entry = storage.find_or_create_by(key: key)
            value = BSON::Binary.new(value.to_msgpack)
            entry.value = value
            entry.save!
            value
          end

          def get(storage, key)
            first = storage.where(key: key).first
            if first and first.value
              return MessagePack.unpack(first.value.data,
                                        options={:symbolize_keys => true})
            end
            nil
          end

          def all(storage)
            keys = []
            storage.each do |entry|
              keys << entry.key
            end
            keys
          end

          def remove(storage, key)
            begin
              storage.where(key: key).delete
            rescue
            end
          end

          def clear_all(storage)
            storage.delete_all
          end
        end
      end

      def get_node(node_id);       Proxy.get(DCellNode, node_id) end
      def set_node(node_id, addr); Proxy.set(DCellNode, node_id, addr) end
      def nodes;                   Proxy.all(DCellNode) end
      def remove_node(node_id);    Proxy.remove(DCellNode, node_id) end
      def clear_all_nodes;         Proxy.clear_all(DCellNode) end

      def get_global(key);         Proxy.get(DCellGlobal, key) end
      def set_global(key, value);  Proxy.set(DCellGlobal, key, value) end
      def global_keys;             Proxy.all(DCellGlobal) end
      def clear_globals;           Proxy.clear_all(DCellGlobal) end

    end
  end
end
