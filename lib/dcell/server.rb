module DCell
  # Servers handle incoming 0MQ traffic
  class Server
    include Celluloid::ZMQ

    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
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
        request = decode_message message
      rescue InvalidMessageError => ex
        Celluloid.logger.warn "couldn't decode message: #{ex}"
        return
      end

      case request
      when LookupRequest
        Celluloid.logger.debug "LookupRequest: #{request.caller.address} is looking up #{request.name.inspect}"
        request.caller << SuccessResponse.new(request.id, Celluloid::Actor[request.name])
      when MessageRequest
        recipient = DCell::Registry.find request.recipient
        recipient << request.message
      else
        Celluloid.logger.warn "Unrecognized DCell request: #{message}"
      end
    end

    class InvalidMessageError < StandardError; end # undecodable message

    # Decode incoming messages
    def decode_message(message)
      if message[0..1].unpack("CC") == [Marshal::MAJOR_VERSION, Marshal::MINOR_VERSION]
        begin
          Marshal.load message
        rescue => ex
          raise InvalidMessageError, "invalid message: #{ex}"
        end
      else raise InvalidMessageError, "couldn't determine message format: #{message}"
      end
    end

    # Terminate this server
    def terminate
      @socket.close
      super
    end
  end
end
