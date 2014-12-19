module DCell
  # A proxy object for a mailbox that delivers messages to the real mailbox on
  # a remote node on a server far, far away...
  class MailboxProxy
    class InvalidNodeError < StandardError; end

    def initialize(address)
      mailbox_id, node_id = address.split("@")

      # Create a proxy to the mailbox on the remote node
      raise ArgumentError, "no mailbox_id given" unless mailbox_id
     
      @node_id = node_id
      @node = Node[node_id]
      raise ArgumentError, "invalid node_id given" unless @node
      
      @mailbox_id = mailbox_id
    end

    # name@host style address
    def address
      "#{@mailbox_id}@#{@node_id}"
    end

    def inspect
      "#<DCell::MailboxProxy:0x#{object_id.to_s(16)} #{address}>"
    end

    def kill
      @node = nil
    end

    # Send a message to the mailbox
    def <<(message)
      raise ::Celluloid::DeadActorError unless @node
      @node.async.send_message Message::Relay.new(self, message)
    end

    # Is the remote mailbox still alive?
    def alive?
      true # FIXME: hax!
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      "#{@mailbox_id}@#{@node_id}"
    end

    # Loader for custom marshal format
    def self._load(address)
      if mailbox = DCell::Router.find(address)
        mailbox
      else
        DCell::MailboxProxy.new(address)
      end
    end
  end
end
