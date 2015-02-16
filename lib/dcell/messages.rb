module DCell
  class Message
    attr_accessor :id

    def initialize
      # Memoize the original object ID so it will get marshalled
      # Perhaps this should use a real UUID scheme
      @id = object_id
    end

    def respond(rsp)
      node = Node[@sender[:id]]
      if node
        node.async.send_message rsp
      else
        Logger.warn "Node #{@sender[:id]} gone"
      end
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

      def to_msgpack(pk=nil)
        {
          :type => self.class.name,
          :id   => @id,
          :args => [@from]
        }.to_msgpack(pk)
      end
    end

    # Farewell messages notifies that remote node dies
    class Farewell < Message
      def initialize
        @id = DCell.id
      end

      def dispatch
        node = DCell::NodeCache.find @id
        node.detach if node
      end

      def to_msgpack(pk=nil)
        {
          :type => self.class.name,
          :id   => @id,
        }.to_msgpack(pk)
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
        actor = DCell.get_local_actor @name
        methods = nil
        if actor
          methods = actor.class.instance_methods(false)
        end
        respond SuccessResponse.new(@id, @sender[:address], methods)
      end

      def to_msgpack(pk=nil)
        {
          :type => self.class.name,
          :id   => @id,
          :args => [@sender, @name]
        }.to_msgpack(pk)
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
        respond SuccessResponse.new(@id, @sender[:address], DCell.local_actors)
      end

      def to_msgpack(pk=nil)
        {
          :type => self.class.name,
          :id   => @id,
          :args => [@sender]
        }.to_msgpack(pk)
      end
    end

    # Relay a message to the given recipient
    class Relay < Message
      attr_reader :sender, :message

      def initialize(sender, message)
        super()
        @sender, @message = sender, message
      end

      def __dispatch(actor)
        value = nil
        if @message[:block]
          Celluloid::Actor::call actor.mailbox, @message[:meth], *@message[:args] {|v| value = v}
        else
          value = Celluloid::Actor::call actor.mailbox, @message[:meth], *@message[:args]
        end
         SuccessResponse.new(@id, @sender[:address], value)
      rescue => e
        ErrorResponse.new(@id, @sender[:address], {:class => e.class.name, :msg => e.to_s})
      end

      def dispatch
        actor = DCell.get_local_actor @message[:actor].to_sym
        if @message[:async]
          Celluloid::Actor::async actor.mailbox, @message[:meth], *@message[:args]
          return
        end
        rsp = __dispatch actor
        respond rsp
      end

      def to_msgpack(pk=nil)
        {
          :type => self.class.name,
          :id   => @id,
          :args => [@sender, @message]
        }.to_msgpack(pk)
      end
    end
  end
end
