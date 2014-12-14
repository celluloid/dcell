module DCell
  # Servers handle incoming 0MQ traffic
  class PullServer
    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
    def initialize(cell, logger=Logger)
      @logger = logger
      @socket = Celluloid::ZMQ::PullSocket.new

      begin
        @socket.bind(cell.addr)
        real_addr = @socket.get(::ZMQ::LAST_ENDPOINT).strip
        cell.addr = real_addr
        @socket.linger = 1000
      rescue IOError
        @socket.close
        raise
      end
    end

    def close
      @socket.close if @socket
    end

    # Handle incoming messages
    def handle_message(message)
      begin
        message = decode_message message
      rescue InvalidMessageError => ex
        @logger.crash("couldn't decode message", ex)
        return
      end

      begin
        message.dispatch
      rescue => ex
        @logger.crash("message dispatch failed", ex)
      end
    end

    class InvalidMessageError < StandardError; end # undecodable message

    # Decode incoming messages
    def decode_message(message)
      begin
        msg = MessagePack.unpack(message, options={:symbolize_keys => true})
      rescue => ex
        raise InvalidMessageError, "couldn't unpack message: #{ex}"
      end
      begin
        klass = Utils::full_const_get msg[:type]
        o = klass.new *msg[:args]
        if o.respond_to? :id and msg[:id]
          o.id = msg[:id]
        end
        o
      rescue => ex
        raise InvalidMessageError, "invalid message: #{ex}"
      end
    end
  end

  class Server < PullServer
    include Celluloid::ZMQ

    finalizer :close

    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
    def initialize(cell)
      super(cell)
      # The gossip protocol is dependent on the node manager
      link Celluloid::Actor[:node_manager]
      async.run
    end

    # Wait for incoming 0MQ messages
    def run
      while true
        async.handle_message @socket.read
      end
    end
  end
end
