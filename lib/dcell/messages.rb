module DCell
  class Message
    attr_reader :id

    def initialize
      # Memoize the original object ID so it will get marshalled
      # Perhaps this should use a real UUID scheme
      @id = object_id
    end

    # Gossip messages contain health and membership information
    class Gossip < Message
      def initialize(peers, data)
        @peers, @data = peers, data
      end

      def dispatch
        Node.handle_gossip(@peers, @data)
      end
    end

    # Query a node for the address of an actor
    class Find < Message
      attr_reader :caller, :name

      def initialize(caller, name)
        super()
        @caller, @name = caller, name
      end

      def dispatch
        @caller << SuccessResponse.new(@id, Celluloid::Actor[@name])
      end
    end

    # List all registered actors
    class List < Message
      attr_reader :caller

      def initialize(caller)
        super()
        @caller = caller
      end

      def dispatch
        @caller << SuccessResponse.new(@id, Celluloid::Actor.registered)
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

    # Send a system event to the given recipient
    class SystemEvent < Message
      attr_reader :recipient, :event

      def initialize(recipient, event)
        super()
        @recipient, @event = recipient, event
      end

      def dispatch
        @recipient << @event
      end
    end
  end
end
