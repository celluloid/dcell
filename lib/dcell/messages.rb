module DCell
  class Message
    attr_writer :id

    def id
      @id ||= Celluloid.uuid
      @id
    end

    def __respond(rsp, pipe)
      node = Node[@sender[:id]]
      if node
        node.async.send_message rsp, pipe
      else
        Logger.warn "Node #{@sender[:id]} gone"
      end
    end

    def respond(rsp)
      __respond rsp, :response
    end

    def exception(e)
      respond ErrorResponse.new(id, @sender[:address], {class: e.class.name, msg: e.to_s, tb: e.backtrace})
    end

    # A request to open relay pipe
    class RelayOpen < Message
      def initialize(sender)
        @id = DCell.id
        @sender = sender
      end

      def dispatch
        node = DCell::Node[id]
        node.handle_relayopen
        respond SuccessResponse.new(id, @sender[:address], node.rserver.addr)
      rescue => e
        # :nocov:
        exception e
        # :nocov:
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
          args: [@sender]
        }.to_msgpack(pk)
      end
    end

    # Heartbeat messages inform other nodes this node is healthy
    class Heartbeat < Message
      def initialize(from)
        @id = DCell.id
        @from = from
      end

      def dispatch
        node = DCell::Node[id]
        node.handle_heartbeat @from if node
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
          args: [@from]
        }.to_msgpack(pk)
      end
    end

    # Farewell message notifies that remote node dies
    class Farewell < Message
      def initialize
        @id = DCell.id
      end

      def dispatch
        node = DCell::NodeCache.find id
        node.detach if node and node.alive?
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
        }.to_msgpack(pk)
      end
    end

    # Ping message checks if remote node is alive or not
    class Ping < Message
      def initialize(sender)
        @sender = sender
      end

      def dispatch
        respond SuccessResponse.new(id, @sender[:address], true)
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
          args: [@sender]
        }.to_msgpack(pk)
      end
    end

    # Query a node for the address of an actor
    class Find < Message
      attr_reader :sender, :name

      def initialize(sender, name)
        @sender, @name = sender, name
      end

      def dispatch
        actor = DCell.get_local_actor @name
        methods = nil
        if actor
          methods = actor.class.instance_methods(false)
        end
        respond SuccessResponse.new(id, @sender[:address], methods)
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
          args: [@sender, @name]
        }.to_msgpack(pk)
      end
    end

    # List all registered actors
    class List < Message
      attr_reader :sender

      def initialize(sender)
        @sender = sender
      end

      def dispatch
        respond SuccessResponse.new(id, @sender[:address], DCell.local_actors)
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
          args: [@sender]
        }.to_msgpack(pk)
      end
    end

    # Relay a message to the given recipient
    class Relay < Message
      attr_reader :sender, :message

      def initialize(sender, message)
        @sender, @message = sender, message
      end

      def respond(rsp)
        __respond rsp, :relay
      end

      def success(value)
        respond SuccessResponse.new(id, @sender[:address], value)
      end

      def dispatch
        actor = DCell.get_local_actor @message[:actor].to_sym
        begin
          actor.async :____dcell_dispatch, self
        rescue => e
          exception e
        end
      end

      def to_msgpack(pk=nil)
        {
          type: self.class.name,
          id:   id,
          args: [@sender, @message]
        }.to_msgpack(pk)
      end
    end
  end
end
