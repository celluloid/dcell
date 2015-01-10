module DCell
  class Message
    attr_accessor :id

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

      def to_msgpack(pk=nil)
        {
          :type => self.class.name,
          :id   => @id,
          :args => [@from]
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
        actor = Celluloid::Actor[@name]
        mailbox, methods = nil, nil
        if actor
          mailbox, methods = actor.mailbox, actor.class.instance_methods(false)
        end
        Node[@sender[:id]] << SuccessResponse.new(@id, @sender[:address], [mailbox, methods])
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
        Node[@sender[:id]] << SuccessResponse.new(@id, @sender[:address], Celluloid::Actor.registered)
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

      def find_actor(mailbox)
        ::Thread.list.each do |t|
          if actor = t[:celluloid_actor]
            return actor if actor.mailbox.address == mailbox[:address]
          end
        end
        nil
      end

      def dispatch
        actor = find_actor(message[:mailbox])
        if actor
          begin
            value = nil
            if message[:block]
              Celluloid::Actor::call actor.mailbox, message[:meth], *message[:args] {|v| value = v}
            else
              value = Celluloid::Actor::call actor.mailbox, message[:meth], *message[:args]
            end
            rsp = SuccessResponse.new(@id, @sender[:address], value)
          rescue => e
            rsp = ErrorResponse.new(@id, @sender[:address], {:class => RuntimeError.name, :msg => e.to_s})
          end
        else
          rsp = DeadActorResponse.new(@id, @sender[:address], nil)
        end
        Node[@sender[:id]].async.send_message rsp
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
