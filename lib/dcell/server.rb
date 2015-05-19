module DCell
  # Servers handle incoming 0MQ traffic
  module MessageHandler
    class InvalidMessageError < StandardError; end
    extend self

    # Handle incoming messages
    def handle_message(message)
      begin
        message = decode_message message
      rescue InvalidMessageError => ex
        Logger.crash("couldn't decode message", ex)
        return
      end

      begin
        message.dispatch
      rescue => ex
        Logger.crash("message dispatch failed", ex)
      end
    end

    # Decode incoming messages
    def decode_message(message)
      begin
        msg = MessagePack.unpack(message, symbolize_keys: true)
      rescue => ex
        raise InvalidMessageError, "couldn't unpack message: #{ex}"
      end
      begin
        klass = Utils.full_const_get msg[:type]
        o = klass.new(*msg[:args])
        o.id = msg[:id] if o.respond_to?(:id=) && msg[:id]
        o
      rescue => ex
        raise InvalidMessageError, "invalid message: #{ex}"
      end
    end
  end

  class Server
    include Celluloid::ZMQ
    include MessageHandler

    attr_accessor :farewell

    finalizer :shutdown

    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
    def initialize(socket)
      @socket = socket
      @farewell = nil
      async.run
    end

    def send_farewell
      return unless @farewell
      msg = @farewell.call
      return unless msg
      @socket.write msg
    rescue
    end

    def shutdown
      return unless @socket
      send_farewell
      @socket.close
      instance_variables.each { |iv| remove_instance_variable iv }
    end

    def write(id, msg)
      if @socket.is_a? Celluloid::ZMQ::RouterSocket
        @socket.write id, msg
      else
        @socket.write msg
      end
    end

    # Wait for incoming 0MQ messages
    def run
      while true
        message = @socket.read_multipart
        if @socket.is_a? Celluloid::ZMQ::RouterSocket
          message = message[1]
        else
          message = message[0]
        end
        handle_message message
      end
    end
  end

  # Sets up main DCell request server
  class RequestServer < Server
    def initialize
      privkey = DCell.crypto ? DCell.crypto_keys[:privkey] : nil
      socket, addr = Socket.server(DCell.addr, DCell.id, privkey)
      DCell.addr = addr
      super(socket)
    end
  end

  # Sets up node relay server
  class RelayServer < Server
    attr_reader :addr

    def initialize
      uri = URI(DCell.addr)
      addr = "#{uri.scheme}://#{uri.host}:*"
      privkey = DCell.crypto ? DCell.crypto_keys[:privkey] : nil
      socket, @addr = Socket.server(addr, DCell.id, privkey)
      super(socket)
    end
  end

  # Sets up client server
  class ClientServer < Server
    def initialize(addr, linger, pubkey)
      socket = Socket.client(addr, DCell.id, pubkey, linger)
      super(socket)
    end
  end
end
