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

      # Find a mailbox by its ID
      def find(mailbox_id)
        @lock.synchronize do
          ref = @table[mailbox_id]
          return unless ref
          begin
            ref.__getobj__
          rescue WeakRef::RefError
            # The referenced actor is dead, so prune the registry
            @table.delete mailbox_id
            nil
          end
        end
      end

      # Route a message to a given mailbox ID
      def route(mailbox_id, message)
        recipient = find mailbox_id

        if recipient
          recipient << message
        else
          warning = "received message for invalid actor: #{mailbox_id.inspect}"
          Celluloid.logger.debug warning if Celluloid.logger
        end
      end

      # Route a system event to a given mailbox ID
      def route_system_event(mailbox_id, event)
        puts "Routing system event: #{event.inspect}"
        recipient = find mailbox_id

        if recipient
          recipient.system_event event
        else
          warning = "received message for invalid actor: #{mailbox_id.inspect}"
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
