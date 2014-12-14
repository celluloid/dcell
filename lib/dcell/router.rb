require 'weakref'

module DCell
  # Route incoming messages to their recipient actors
  class Router
    @mutex     = Mutex.new
    @mailboxes = {}

    class << self
      # Enter a mailbox into the registry
      def register(mailbox)
        @mutex.synchronize do
          address = mailbox.address
          ref = @mailboxes[address]
          @mailboxes[address] = WeakRef.new(mailbox) unless ref && ref.weakref_alive?

          address
        end
      end

      # Find a mailbox by its address
      def find(address)
        @mutex.synchronize do
          begin
            ref = @mailboxes[address]
            return unless ref
            ref.__getobj__
          rescue WeakRef::RefError
            # The referenced actor is dead, so prune the registry
            @mailboxes.delete address
            nil
          end
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
