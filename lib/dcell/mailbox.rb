module DCell
  # Mailboxes are inter-node communcation endpoints. Each has a unique address
  class Mailbox
    include Celluloid::ZMQ

    # Bind to the given ZeroMQ address (in URL form ala tcp://host:port)
    def initialize
      @addr   = DCell.addr
      @socket = DCell.zmq_context.socket(::ZMQ::PULL)

      unless ::ZMQ::Util.resultcode_ok? @socket.setsockopt(::ZMQ::LINGER, 0)
        @socket.close
        raise "couldn't set ZMQ::LINGER: #{::ZMQ::Util.error_string}"
      end

      unless ::ZMQ::Util.resultcode_ok? @socket.bind(@addr)
        @socket.close
        raise "couldn't bind to #{@addr}: #{::ZMQ::Util.error_string}"
      end

      run!
    end

    # Wait for incoming 0MQ messages
    def run
      while true
        wait_readable @socket
        message = ''

        rc = @socket.recv_string message
        if ::ZMQ::Util.resultcode_ok? rc
          handle_message message
        else
          raise "error receiving ZMQ string: #{::ZMQ::Util.error_string}"
        end
      end
    end

    # Handle incoming messages
    def handle_message(message)
      begin
        message = decode_message message
      rescue InvalidMessageError => ex
        Celluloid.logger.warn "got an unrecognized message: #{message.inspect}"
        return
      end

      puts "got a message: #{message.inspect}"
    end

    class InvalidMessageError < StandardError; end # undecodable message

    # Decode incoming messages
    def decode_message(message)
      # Marshal 4.8 format
      if message[0..1].unpack("CC") == [4, 8]
        begin
          Marshal.load message
        rescue => ex
          raise InvalidMessageError, "invalid message: #{ex}"
        end
      else raise InvalidMessageError, "couldn't determine message format"
      end
    end

    # Terminate this server
    def terminate
      @socket.close
      super
    end
  end
end
