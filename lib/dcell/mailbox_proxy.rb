module DCell
  # A proxy object for a mailbox that delivers messages to the real mailbox on
  # a remote node on a server far, far away...
  class MailboxProxy
    class InvalidNodeError < StandardError; end

    def initialize(node_id, node_addr, mailbox_id)
      raise ArgumentError, "no mailbox_id given" unless mailbox_id
      
      @node_id = node_id
      @node = Node[node_id]
      @node = Node.new(node_id, node_addr) unless @node
      @mailbox_id = mailbox_id
    end

    # name@host style address
    def address
      "#{@mailbox_id}@#{@node_id}"
    end

    def inspect
      "#<DCell::MailboxProxy:0x#{object_id.to_s(16)} #{address}>"
    end

    # Send a message to the mailbox
    def <<(message)
      @node.send_message! Message::Relay.new(self, message)
    end

    # Send a system event
    def system_event(event)
      @node.send_message! Message::SystemEvent.new(self, event)
    end

    # Is the remote mailbox still alive?
    def alive?
      true # FIXME: hax!
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      "#{@mailbox_id}@#{@node_id}@#{@node_addr}"
    end

    # Loader for custom marshal format
    def self._load(string)
      mailbox_id, node_id, node_addr = string.split("@")

      if DCell.id == node_id
        # If we're on the local node, find the real mailbox
        mailbox = DCell::Router.find mailbox_id
        raise "tried to unmarshal dead Celluloid::Mailbox: #{mailbox_id}" unless mailbox
        mailbox
      else
        # Create a proxy to the mailbox on the remote node
        DCell::MailboxProxy.new(node_id, node_addr, mailbox_id)
      end
    end
  end
end
