module DCell
  module Socket
    extend self

    def curve_genkeys
      pub, priv = ZMQ::Util.curve_keypair
      {pubkey: pub, privkey: priv}
    end

    def set_server_key(socket, privkey)
      return unless privkey
      socket.set(ZMQ::CURVE_SERVER, 1)
      socket.set(ZMQ::CURVE_SECRETKEY, privkey)
    end

    def set_client_key(socket, pubkey)
      return unless pubkey
      local = curve_genkeys
      socket.set(ZMQ::CURVE_SERVERKEY, pubkey)
      socket.set(ZMQ::CURVE_PUBLICKEY, local[:pubkey])
      socket.set(ZMQ::CURVE_SECRETKEY, local[:privkey])
    end

    # Bind to the given 0MQ address (in URL form ala tcp://host:port)
    def server(addr, id, privkey=nil, linger=1000)
      fail IOError unless addr && id

      socket = Celluloid::ZMQ::RouterSocket.new
      fail IOError unless socket
      begin
        set_server_key socket, privkey
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
    def client(addr, id, pubkey=nil, linger=1000)
      fail IOError unless addr && id

      socket = Celluloid::ZMQ::DealerSocket.new
      fail IOError unless socket
      begin
        set_client_key socket, pubkey
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
