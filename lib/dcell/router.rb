require 'weakref'

module DCell
  # Route incoming messages to their recipient actors
  class Router
    @mutex = Mutex.new
    @table = {}

    class << self
      # Enter a mailbox into the registry
      def register(mailbox)
        @mutex.lock
        begin
          id = mailbox.object_id.to_s(16)
          ref = @table[id]
          unless ref && ref.weakref_alive?
            @table[id] = WeakRef.new(mailbox)
          end
          id
        ensure
          @mutex.unlock rescue nil
        end
      end

      # Find a mailbox by its ID
      def find(mailbox_id)
        @mutex.lock
        begin
          ref = @table[mailbox_id]
          return unless ref
          ref.__getobj__
        rescue WeakRef::RefError
          # The referenced actor is dead, so prune the registry
          @table.delete mailbox_id
          nil
        ensure
          @mutex.unlock rescue nil
        end
      end

      # Route a message to a given mailbox ID
      def route(mailbox_id, message)
        recipient = find mailbox_id

        if recipient
          recipient << message
        else
          Celluloid::Logger.debug("received message for invalid actor: #{mailbox_id.inspect}")
        end
      end

      # Route a system event to a given mailbox ID
      def route_system_event(mailbox_id, event)
        recipient = find mailbox_id

        if recipient
          recipient.system_event event
        else
          Celluloid::Logger.debug("received message for invalid actor: #{mailbox_id.inspect}")
        end
      end

      # Prune all entries that point to dead objects
      def gc
        @mutex.synchronize do
          @table.each do |id, ref|
            @table.delete id unless ref.weakref_alive?
          end
        end
      end
    end
  end
end
