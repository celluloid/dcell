require 'mongoid'
require 'bson'

module DCell
  module Registry
    class MongodbAdapter
      include Node
      include Global

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

        @node_registry = Registry.new(DCellNode)
        @global_registry = Registry.new(DCellGlobal)
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

      class Registry
        def initialize(storage)
          @storage = storage
        end

        def _set(key, value, unique)
          entry = @storage.find_or_create_by(key: key)
          raise KeyExists if entry.value and unique
          value = BSON::Binary.new(value.to_msgpack)
          entry.value = value
          entry.save!
          value
        end

        def set(key, value)
          _set(key, value, false)
        end

        def get(key)
          first = @storage.where(key: key).first
          if first and first.value
            return MessagePack.unpack(first.value.data,
                                      options={:symbolize_keys => true})
          end
          nil
        end

        def all
          keys = []
          @storage.each do |entry|
            keys << entry.key
          end
          keys
        end

        def remove(key)
          begin
            @storage.where(key: key).delete
          rescue
          end
        end

        def clear_all
          @storage.delete_all
        end
      end
    end
  end
end
