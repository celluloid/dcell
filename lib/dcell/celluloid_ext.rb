# Celluloid mailboxes are the universal message exchange points. You won't
# be able to marshal them though, unfortunately, because they contain
# mutexes.
#
# DCell provides a message routing layer between nodes that can direct
# messages back to local mailboxes. To accomplish this, DCell adds custom
# marshalling to mailboxes so that if they're unserialized on a remote
# node you instead get a proxy object that routes messages through the
# DCell overlay network back to the node where the actor actually exists

module Celluloid
  class Mailbox
    # This custom dumper registers actors with the DCell registry so they can
    # be reached remotely.
    def _dump(level)
      mailbox_id = DCell::Registry.register self
      "#{mailbox_id}@#{DCell.id}"
    end

    # Create a mailbox proxy object which routes messages over DCell's overlay
    # network and back to the original mailbox
    def self._load(string)
      mailbox_id, node_id = string.split("@")
      DCell::MailboxProxy.new(node_id, mailbox_id)
    end
  end
end
