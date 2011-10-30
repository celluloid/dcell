module DCell
  # Mailboxes are inter-node communcation endpoints. Each has a unique address
  class Mailbox
    include Celluloid::ZMQ

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
      run!
    end

    # Wait for incoming 0MQ messages
    def run
      while true
        wait_readable(@socket)

        message = ''
        rc = @socket.recv_string(message)

        if zmq_success? rc
          puts "Got a message: #{message}"
        else
          raise "error receiving ZMQ string: #{rc}"
        end
      end
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
