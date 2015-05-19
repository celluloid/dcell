module DCell
  # Node communication helpers
  class Node
    module Communication
      def init_comm(addr)
        @addr = addr
        @requests = ResourceManager.new
        @socket, @rsocket, @raddr = nil, nil, nil
        @rserver = nil
      end

      def close_comm
        [@socket, @rsocket, @rserver].each do |socket|
          next unless socket && socket.alive?
          socket.terminate
        end
      end

      def save_request(request)
        @requests.register(request.id) { request }
      end

      def delete_request(request)
        @requests.delete request.id
      end

      def cancel_requests
        @requests.each do |id, request|
          address = request.sender.address
          rsp = CancelResponse.new id, address
          rsp.dispatch
        end
      end

      def rserver
        return @rserver if @rserver
        @rserver = RelayServer.new
      end

      # Obtain socket for relay messages
      def rsocket
        return @rsocket if @rsocket
        send_relayopen unless @raddr
        linger = @heartbeat_timeout * 1000
        pubkey = Directory[@id].pubkey
        @rsocket = ClientServer.new @raddr, linger, pubkey
      end

      # Obtain socket for management messages
      def socket
        return @socket if @socket
        linger = @heartbeat_timeout * 1000
        pubkey = Directory[@id].pubkey
        @socket = ClientServer.new @addr, linger, pubkey
        @socket.farewell = farewell
        transition :connected
        @socket
      end

      # Pack and send a message to another DCell node
      def send_message(message, pipe=:request)
        queue = nil
        if pipe == :request
          queue = socket
        elsif pipe == :response
          queue = Celluloid::Actor[:server]
        elsif pipe == :relay
          queue = rsocket
        end

        begin
          message = message.to_msgpack
        rescue => e
          abort e
        end
        queue.async.write @id, message
      end

      # Send request and wait for response
      def push_request(request, pipe=:request, timeout=@request_timeout)
        send_message request, pipe
        save_request request
        response = receive(timeout) do |msg|
          msg.respond_to?(:request_id) && msg.request_id == request.id
        end
        delete_request request
        abort NoResponseError.new unless response
        response
      end

      # Send request and handle unroll response
      def send_request(request, pipe=:request, timeout=nil)
        response = push_request request, pipe, timeout
        return if response.is_a? CancelResponse
        if response.is_a? ErrorResponse
          value = response.value
          klass = Utils.full_const_get value[:class]
          exception = klass.new value[:msg]
          exception.set_backtrace value[:tb]
          abort exception
        end
        response.value
      end
    end
  end
end
