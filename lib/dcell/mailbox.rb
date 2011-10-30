module DCell
  # Mailboxes are inter-node communcation endpoints. Each has a unique address
  class Mailbox
    include Celluloid

    # Confusingly enough, a mailbox has a mailbox. This is a Celluloid mailbox
    # used for intra-node (as oppsed to inter-node) communication, but one
    # augmented with special abilities that let it multiplex 0MQ sockets
    use_mailbox DCell::ZMQ::Mailbox

    # Bind to the given ZeroMQ address (in URL form ala tcp://host:port)
    def initialize
      @addr   = DCell.addr
      @socket = DCell.zmq_context.socket(::ZMQ::PULL)

      unless zmq_success? @socket.setsockopt(::ZMQ::LINGER, 0)
        @socket.close
        raise "couldn't ZMQ::LINGER your socket for some reason"
      end

      unless zmq_success? @socket.bind(@addr)
        @socket.close
        raise "couldn't bind to #{@addr}. Is the address in use?"
      end

      #@poller.register @socket, ZMQ::POLLIN
    end

    # Terminate this server
    def terminate
      @socket.close
      super
    end

    # Did the given 0MQ operation succeed?
    def zmq_success?(result)
      ::ZMQ::Util.resultcode_ok? result
    end
  end
end
