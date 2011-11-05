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

    def inspect
      "#<DCell::MailboxProxy:0x#{object_id.to_s(16)} #{@mailbox_id}@#{@node_id}>"
    end
  end
end
