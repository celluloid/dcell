module DCell
  # Proxy object for actors that live on remote nodes
  class ActorProxy
    include Celluloid

    def initialize(lnode, actor, methods)
      @lnode, @actor = lnode, actor
      methods.each do |meth|
        self.class.send(:define_method, meth) do |*args, &block|
          begin
            ______method_missing meth.to_sym, *args, &block
          rescue AbortError => e
            cause = e.cause
            raise Celluloid::DeadActorError.new if cause.kind_of? Celluloid::DeadActorError
            raise RuntimeError, cause
          end
        end
        self.class.send(:define_method, "____async_#{meth}") do |*args|
          begin
            ______async_method_missing meth.to_sym, *args
          # :nocov: as really hard to simulate
          rescue AbortError => e
            cause = e.cause
            raise Celluloid::DeadActorError.new if cause.kind_of? Celluloid::DeadActorError
            raise RuntimeError, cause
          end
          # :nocov:
        end
      end
    end

    private
    def ______method_missing(meth, *args, &block)
      message = {actor: @actor, meth: meth, args: args, block: block_given?}
      begin
        res = @lnode.relay message
        if block_given?
          yield res
        else
          res
        end
      rescue Celluloid::Task::TerminatedError
        abort Celluloid::DeadActorError.new
      end
    end

    def ______async_method_missing(meth, *args)
      message = {actor: @actor, meth: meth, args: args, async: true}
      begin
        @lnode.async_relay message
      # :nocov: as really hard to simulate
      rescue Celluloid::Task::TerminatedError
        abort Celluloid::DeadActorError.new
      end
      # :nocov:
    end
  end
end
