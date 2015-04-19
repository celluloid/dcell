require 'weakref'

module DCell
  class ResourceManagerConflict < RuntimeError; end

  class ResourceManager
    def initialize
      @lock = Mutex.new
      @items = {}
    end

    # Register an item inside the cache if it does not yet exist
    # If the item is not found inside the cache the block attached should return a valid reference
    def register(id, &block)
      @lock.synchronize do
        ref = @items[id]
        return ref.__getobj__ if ref && ref.weakref_alive?
      end
      item = block.call
      return nil unless item
      ref = WeakRef.new(item)
      @lock.synchronize do
        old = @items[id]
        if old && old.weakref_alive? && old.__getobj__.object_id != item.object_id
          # :nocov:
          fail ResourceManagerConflict, 'Resource collision'
          # :nocov:
        end
        @items[id] = ref
        ref.__getobj__
      end
    end

    # Iterates over registered and alive items
    def each
      @lock.synchronize do
        @items.each do |id, ref|
          yield id, ref.__getobj__ rescue WeakRef::RefError
        end
      end
    end

    # Clears all items from the cache
    # If block is given, iterates over the cached items
    def clear
      @lock.synchronize do
        if block_given?
          @items.each do |id, ref|
            yield id, ref.__getobj__ rescue WeakRef::RefError
          end
        end
        @items.clear
      end
    end

    # Finds an item by its ID
    def find(id)
      @lock.synchronize do
        begin
          ref = @items[id]
          return unless ref
          ref.__getobj__
        rescue WeakRef::RefError
          # :nocov:
          @items.delete id
          nil
          # :nocov:
        end
      end
    end

    # Delete item from the cache
    def delete(id)
      @lock.synchronize do
        @items.delete id
      end
    end
  end
end
