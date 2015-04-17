module DCell
  module Socket
    extend self

    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
    def server(addr, id, linger=1000)
      raise IOError unless addr and id

      socket = Celluloid::ZMQ::RouterSocket.new
      raise IOError unless socket
      begin
        socket.identity = id
        socket.bind(addr)
        socket.linger = linger
      rescue IOError
        socket.close
        raise
      end
      addr = socket.get(::ZMQ::LAST_ENDPOINT).strip
      [socket, addr]
    end

    # Connect to the given 0MQ address (in URL form ala tcp://host:port)
    def client(addr, id, linger=1000)
      raise IOError unless addr and id

      socket = Celluloid::ZMQ::DealerSocket.new
      raise IOError unless socket
      begin
        socket.identity = id
        socket.connect addr
        socket.linger = linger
      rescue IOError
        socket.close
        raise
      end
      socket
    end
  end
end
