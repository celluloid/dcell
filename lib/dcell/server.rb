module DCell
  # Servers handle incoming 0MQ traffic
  class Server
    include Celluloid::ZMQ

    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
    def initialize
      # The gossip protocol is dependent on the node manager
      link Celluloid::Actor[:node_manager]

      @addr   = DCell.addr
      @socket = PullSocket.new

      begin
        @socket.bind(@addr)
      rescue IOError
        @socket.close
        raise
      end

      run!
    end

    # Wait for incoming 0MQ messages
    def run
      while true; handle_message! @socket.read; end
    end

    # Shut down the server
    def finalize
      @socket.close if @socket
    end

    # Handle incoming messages
    def handle_message(message)
      begin
        message = decode_message message
      rescue InvalidMessageError => ex
        Celluloid::Logger.warn("couldn't decode message: #{ex.class}: #{ex}")
        return
      end

      begin
        message.dispatch
      rescue => ex
        Celluloid::Logger.crash("DCell::Server: message dispatch failed", ex)
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
