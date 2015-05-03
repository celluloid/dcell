module DCell
  # Node private RPC
  class Node
    module RPC
      def init_rpc
        @remote_dead = false
        @leech = false
      end

      def remote_dead
        @remote_dead = true
      end

      # Relay message to remote actor
      def relay(message)
        request = Message::Relay.new(Thread.mailbox, message)
        send_request request, :relay
      end

      # Relay async message to remote actor
      def async_relay(message)
        request = Message::Relay.new(Thread.mailbox, message)
        send_message request, :relay
      end

      # Goodbye message to remote actor
      def farewell
        proc do
          return if @remote_dead || DCell.id == @id
          Message::Farewell.new.to_msgpack
        end
      end

      # Send a heartbeat message after the given interval
      def send_heartbeat
        return if DCell.id == @id
        request = DCell::Message::Heartbeat.new @id
        send_message request, @leech ? :response : :request
        @heartbeat = after(@heartbeat_rate) { send_heartbeat }
      end

      # Handle an incoming heartbeat for this node
      def handle_heartbeat(from)
        return if from == @id
        @leech = true unless state == :connected
        transition :connected
        transition :partitioned, delay: @heartbeat_timeout
      end

      # Send an advertising message
      def send_relayopen
        request = Message::RelayOpen.new(Thread.mailbox)
        @raddr = send_request request
      end

      # Handle an incoming node advertising message for this node
      def handle_relayopen
        @rsocket = rserver
      end
    end
  end
end
