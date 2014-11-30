require 'weakref'

module DCell
  # A node in a DCell cluster
  class Node
    include Celluloid
    include Celluloid::FSM
    attr_reader :id, :addr

    finalizer :shutdown

    # FSM
    default_state :disconnected
    state :shutdown
    state :disconnected, :to => [:connected, :shutdown]
    state :connected do
      send_heartbeat
      Logger.info "Connected to #{id}"
    end
    state :partitioned do
      @heartbeat.cancel if @heartbeat
      Logger.warn "Communication with #{id} interrupted"
      move_node
    end

    # Singleton methods
    class << self
      include Enumerable
      extend Forwardable

      def_delegators "Celluloid::Actor[:node_manager]", :all, :each, :find, :[], :remove, :update
    end

    def initialize(id, addr)
      @id, @addr = id, addr
      @socket = nil
      @heartbeat = nil
      @calls = Set.new
      @actors = Set.new
      @requests = Set.new
      @lock = Mutex.new

      @heartbeat_rate    = DCell.heartbeat_rate  # How often to send heartbeats in seconds
      @heartbeat_timeout = DCell.heartbeat_timeout # How soon until a lost heartbeat triggers a node partition

      # Total hax to accommodate the new Celluloid::FSM API
      attach self
    end

    def move_node
      @lock.synchronize do
        @calls.each do |call|
          begin
            call.__getobj__.cleanup if call.weakref_alive?
          rescue WeakRef::RefError
          end
        end
        @calls = Set.new
        @actors.each do |actor|
          begin
            actor.__getobj__.mailbox.kill if actor.weakref_alive?
          rescue WeakRef::RefError
          end
        end
        @actors = Set.new
      end
      addr = Directory[id]
      if addr
        update_client_address addr
        @lock.synchronize do
          @requests.each do |request|
            current_actor.mailbox << RetryResponse.new(request, nil)
          end
        end
      else
        terminate
      end
    end

    def update_client_address(addr)
      return @socket if addr == @addr
      @heartbeat.cancel if @heartbeat
      @addr = addr
      if @socket
        @socket.close
        @socket = nil
      end
      socket
    end

    def update_server_address(addr)
      @addr = addr
    end

    def shutdown
      transition :shutdown
      @socket.close if @socket
    end

    # Obtain the node's 0MQ socket
    def socket
      return @socket if @socket

      @socket = Celluloid::ZMQ::PushSocket.new
      begin
        @socket.connect @addr
        @socket.linger = @heartbeat_timeout * 1000
      rescue IOError
        @socket.close
        @socket = nil
        raise
      end
      @addr = @socket.get(::ZMQ::LAST_ENDPOINT).strip

      transition :connected
      @socket
    end

    def send_request(request)
      loop do
        send_message request

        @lock.synchronize do
          @requests << request.id
        end
        response = receive do |msg|
          msg.respond_to?(:request_id) && msg.request_id == request.id
        end
        @lock.synchronize do
          @requests.delete request.id
        end

        next if response.is_a? RetryResponse
        abort response.value if response.is_a? ErrorResponse
        return response.value
      end
    end

    # Find an call registered with a given name on this node
    def find(name)
      request = Message::Find.new(Thread.mailbox, name)
      actor = send_request request
      @lock.synchronize do
        @actors << WeakRef.new(actor)
      end
      actor
    end
    alias_method :[], :find

    # List all registered actors on this node
    def actors
      request = Message::List.new(Thread.mailbox)
      send_request request
    end
    alias_method :all, :actors

    # Send a message to another DCell node
    def send_message(message)
      if message.kind_of? Message::Relay
        call = message.message
        if call.kind_of? Celluloid::SyncCall
          @lock.synchronize do
            @calls << WeakRef.new(call)
          end
        end
      end

      begin
        message = Marshal.dump(message)
      rescue => ex
        abort ex
      end

      socket << message
    end
    alias_method :<<, :send_message
    
    # Send a heartbeat message after the given interval
    def send_heartbeat
      send_message DCell::Message::Heartbeat.new
      @heartbeat = after(@heartbeat_rate) { send_heartbeat }
    end

    # Handle an incoming heartbeat for this node
    def handle_heartbeat
      transition :connected
      transition :partitioned, :delay => @heartbeat_timeout
    end

    # Friendlier inspection
    def inspect
      "#<DCell::Node[#{@id}] @addr=#{@addr.inspect}>"
    end
  end
end
