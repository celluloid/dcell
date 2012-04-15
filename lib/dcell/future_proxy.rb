module DCell
  class FutureProxy
    def initialize(mailbox_id,node_id,node_addr)
      @mailbox_id = mailbox_id
      @node_id = node_id
      @node_addr = node_addr
    end

    def <<(message)
      node = Node[@node_id]
      node = Node.new(@node_id, @node_addr) unless node
      node.send_message! Message::Relay.new(self, message)
    end

    def _dump(level)
      "#{@mailbox_id}@#{@node_id}@#{@node_addr}"
    end

    # Loader for custom marshal format
    def self._load(string)
      mailbox_id, node_id, node_addr = string.split("@")

      if node_id == DCell.id
        future = Router.find(mailbox_id)
        raise "tried to unmarshal dead Celluloid::Future: #{mailbox_id}" unless future
        future
      else
        new(mailbox_id, node_id, node_addr)
      end
    end
  end
end
