module DCell
  # 0MQ server, handling incoming connections from other DCell nodes
  class Server
    include Celluloid::IO

    # Bind to the given ZeroMQ address
    def initialize(zmq_addr)
      @addr = zmq_addr
      @socket = DCell.zmq_context.socket(ZMQ::PULL)

      unless zmq_success? @socket.setsockopt(ZMQ::LINGER, 0)
        raise "couldn't ZMQ::LINGER your socket for some reason"
      end

      unless zmq_success? @socket.bind(@addr)
        raise "couldn't bind to #{host}:#{port}. Is the address in use?"
      end

      @poller = ZMQ::Poller.new
      @poller.register @socket, ZMQ::POLLIN
      @polling_interval = 100 # in milliseconds

      run_once!
    end

    # Wait for 0MQ messages for the given interval
    def run_once
      @poller.poll @polling_interval
      message = @socket.recv_string
      run_once! # async tail call loop CRAZY!
    end

    # Terminate this server
    def terminate
      @server.close
      super
    end

    # Called whenever a new connection is opened
    def on_connect(connection)
      connection.close
    end

    # Did the given 0MQ operation succeed?
    def zmq_success?(result)
      ZMQ::Util.resultcode_ok? result
    end
  end
end
