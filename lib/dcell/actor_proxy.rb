module DCell
  # Proxy object for actors that live on remote nodes
  class ActorProxy
    def initialize(dnode, rmailbox)
      @dnode, @rmailbox = dnode, rmailbox
    end

    def method_missing(meth, *args, &block)
      message = {:mailbox => @rmailbox, :meth => meth, :args => args, :block => block_given?}
      res = @dnode.send_request Message::Relay.new(Thread.mailbox, message)
      if block_given?
        yield res
      else
        res
      end
    end
  end
end
