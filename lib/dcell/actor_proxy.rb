module DCell
  # Proxy object for actors that live on remote nodes
  class ActorProxy
    include Celluloid

    def initialize(lnode, actor, methods)
      @lnode, @actor = lnode, actor

      methods.each do |meth|
        self.class.send(:define_method, meth) do |*args, &block|
          ______any_method_missing :______method_missing, meth, *args, &block
        end
        self.class.send(:define_method, "____async_#{meth}") do |*args|
          ______any_method_missing :______async_method_missing, meth, *args
        end
      end
    end

    private
    def ______any_method_missing(handler, meth, *args, &block)
      begin
        send handler, meth, *args, &block
      rescue Celluloid::Task::TerminatedError
        abort Celluloid::DeadActorError.new
      end
    rescue AbortError => e
      cause = e.cause
      raise Celluloid::DeadActorError.new if cause.kind_of? Celluloid::DeadActorError
      raise RuntimeError, cause
    end

    def ______method_missing(meth, *args, &block)
      message = {actor: @actor, meth: meth, args: args, block: block_given?}
      res = @lnode.relay message
      yield res if block_given?
      res
    end

    def ______async_method_missing(meth, *args)
      message = {actor: @actor, meth: meth, args: args, async: true}
      @lnode.async_relay message
    end
  end
end
