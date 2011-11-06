module DCell
  # A proxy object for a mailbox that delivers messages to the real mailbox on
  # a remote node on a server far, far away...
  class MailboxProxy
    class InvalidNodeError < StandardError; end

    def initialize(node_id, mailbox_id)
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
      # FIXME: custom inspect is here because the default inspect was causing deadlocks
      # This needs further investigation at some point...
      "#<DCell::MailboxProxy:0x#{object_id.to_s(16)} #{address}>"
    end

    # Send a message to the mailbox
    def <<(message)
      @node.send_message! MessageRequest.new(@mailbox_id, message)
    end
  end
end
