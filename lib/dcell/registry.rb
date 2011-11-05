require 'weakref'

module DCell
  # Register addresses of individual mailboxes in order to route incoming messages
  class Registry
    @lock = Mutex.new
    @registry = {}

    # Enter a mailbox into the registry
    def self.register(mailbox)
      id = mailbox.object_id.to_s(16)

      @lock.synchronize do
        ref = @registry[id]
        unless ref && ref.weakref_alive?
          @registry[id] = WeakRef.new(mailbox)
        end
      end

      id
    end

    # Find a mailbox by its actor ID
    def self.find(id)
      @lock.synchronize do
        ref = @registry[id]
        return unless ref
        begin
          ref.__getobj__
        rescue WeakRef::RefError
          # The referenced actor is dead, so prune the registry
          @registry.delete id
          nil
        end
      end
    end

    # Prune all entries that point to dead objects
    def self.gc
      @lock.synchronize do
        @registry.each do |id, ref|
          @registry.delete id unless ref.weakref_alive?
        end
      end
    end
  end
end
