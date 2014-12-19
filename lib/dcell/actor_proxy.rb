module DCell
  # Proxy object for actors that live on remote nodes
  class CellProxy < Celluloid::CellProxy; end

  class ThreadHandleProxy
    def kill
      raise NotImplementedError, "remote kill not supported"
    end

    def join(timeout)
      raise NotImplementedError, "remote join not supported"
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
      @thread  = ThreadHandleProxy.new
      @subject = SubjectProxy.new
      @proxy = Celluloid::ActorProxy.new(@thread, @mailbox)
    end
    attr_reader :mailbox, :thread, :subject, :proxy
  end
end
