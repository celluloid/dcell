module DCell
  # Proxy object for actors that live on remote nodes
  class ActorProxy < Celluloid::ActorProxy; end

  class ThreadHandleProxy
    def kill
      raise "Cannot kill with remote Actors"
    end

    def join
      raise "Cannot join with remote Actors"
    end
  end

  class SubjectProxy
    def class
      "[remote]"
    end
  end

  class Actor
    def initialize(mailbox)
      @mailbox = mailbox
      @thread = ThreadHandleProxy.new
      @subject = SubjectProxy.new
    end
    attr_reader :mailbox, :thread, :subject
  end
end
