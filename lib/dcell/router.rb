require 'weakref'

module DCell
  # Route incoming messages to their recipient actors
  class Router
    @lock = Mutex.new
    @table = {}

    class << self
      # Enter a mailbox into the registry
      def register(mailbox)
        id = mailbox.object_id.to_s(16)

        @lock.synchronize do
          ref = @table[id]
          unless ref && ref.weakref_alive?
            @table[id] = WeakRef.new(mailbox)
          end
        end

        id
      end

      # Find an actor by its ID
      def find(id)
        @lock.synchronize do
          ref = @table[id]
          return unless ref
          begin
            ref.__getobj__
          rescue WeakRef::RefError
            # The referenced actor is dead, so prune the registry
            @table.delete id
            nil
          end
        end
      end
    
      # Route a message to a given actor
      def route(packet)
        recipient = find packet.recipient
        
        if recipient
          recipient << packet.message
        else
          warning = "received message for invalid actor: #{packet.recipient.inspect}"
          Celluloid.logger.debug warning if Celluloid.logger
        end
      end

      # Prune all entries that point to dead objects
      def gc
        @lock.synchronize do
          @table.each do |id, ref|
            @table.delete id unless ref.weakref_alive?
          end
        end
      end
    end
  end
end
