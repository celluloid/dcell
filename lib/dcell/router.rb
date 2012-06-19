require 'weakref'

module DCell
  # Route incoming messages to their recipient actors
  class Router
    @mutex     = Mutex.new
    @addresses = {}
    @mailboxes = {}

    class << self
      # Enter a mailbox into the registry
      def register(mailbox)
        @mutex.lock
        begin
          address = @addresses[mailbox.object_id]
          unless address
            address = Celluloid.uuid
            @addresses[mailbox.object_id] = address
          end

          ref = @mailboxes[address]
          @mailboxes[address] = WeakRef.new(mailbox) unless ref && ref.weakref_alive?

          address
        ensure
          @mutex.unlock rescue nil
        end
      end

      # Find a mailbox by its address
      def find(mailbox_address)
        @mutex.lock
        begin
          ref = @mailboxes[mailbox_address]
          return unless ref
          ref.__getobj__
        rescue WeakRef::RefError
          # The referenced actor is dead, so prune the registry
          @mailboxes.delete mailbox_address
          nil
        ensure
          @mutex.unlock rescue nil
        end
      end

      # Prune all entries that point to dead objects
      def gc
        @mutex.synchronize do
          @mailboxes.each do |id, ref|
            @mailboxes.delete id unless ref.weakref_alive?
          end
        end
      end
    end
  end
end
