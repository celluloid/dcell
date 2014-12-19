module DCell
  class Message
    attr_reader :id

    def initialize
      # Memoize the original object ID so it will get marshalled
      # Perhaps this should use a real UUID scheme
      @id = object_id
    end

    # Heartbeat messages inform other nodes this node is healthy
    class Heartbeat < Message
      def initialize(from)
        @id = DCell.id
        @from = from
      end

      def dispatch
        node = DCell::Node[@id]
        node.handle_heartbeat @from if node
      end
    end

    # Query a node for the address of an actor
    class Find < Message
      attr_reader :sender, :name

      def initialize(sender, name)
        super()
        @sender, @name = sender, name
      end

      def dispatch
        @sender << SuccessResponse.new(@id, Celluloid::Actor[@name])
      end
    end

    # List all registered actors
    class List < Message
      attr_reader :sender

      def initialize(sender)
        super()
        @sender = sender
      end

      def dispatch
        @sender << SuccessResponse.new(@id, Celluloid::Actor.registered)
      end
    end

    # Relay a message to the given recipient
    class Relay < Message
      attr_reader :recipient, :message

      def initialize(recipient, message)
        super()
        @recipient, @message = recipient, message
      end

      def dispatch
        @recipient << @message
      end
    end
  end
end
