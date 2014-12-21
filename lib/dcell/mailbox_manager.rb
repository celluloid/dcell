module DCell
  # Manage mailbox addresses of local actors
  class MailboxManager
    @mailboxes = ResourceManager.new

    class << self
      # Enter a mailbox into the registry
      def register(mailbox)
        address = mailbox.address
        @mailboxes.register(address) {mailbox}
      end

      # Find a mailbox by its address
      def find(address)
        @mailboxes.find address
      end

      # Delete unused mailbox
      def delete(mailbox)
        address = mailbox.address
        @mailboxes.delete address
      end
    end
  end
end
