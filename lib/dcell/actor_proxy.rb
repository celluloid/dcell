module DCell
  # Proxy object for actors that live on remote nodes
  class ActorProxy
    include Celluloid

    def initialize(lnode, rmailbox, methods)
      @lnode, @rmailbox = lnode, rmailbox
      methods.each do |meth|
        self.class.send(:define_method, meth) do |*args, &block|
          ______method_missing meth.to_sym, *args, &block
        end
      end
    end

    private
    def ______method_missing(meth, *args, &block)
      message = {:mailbox => @rmailbox, :meth => meth, :args => args, :block => block_given?}
      res = @lnode.relay message
      if block_given?
        yield res
      else
        res
      end
    end
  end
end
