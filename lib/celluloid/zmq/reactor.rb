module Celluloid
  module ZMQ
    # React to incoming 0MQ and Celluloid events. This is kinda sorta supposed
    # to resemble the Reactor design pattern.
    class Reactor
      def initialize(waker)
        @waker = waker
        @poller = ::ZMQ::Poller.new
        @readers = {}
        @writers = {}

        # Wake up the poller when the mailbox's waker is readable
        # This is broken for whatever reason :(
        #@poller.register nil, ::ZMQ::POLLIN, @waker.io.fileno
      end

      # Wait for the given ZMQ socket to become readable
      def wait_readable(socket, &block)
        monitor_zmq socket, @readers, ::ZMQ::POLLIN, &block
      end

      # Wait for the given ZMQ socket to become writeable
      def wait_writeable(socket, &block)
        monitor_zmq socket, @writers, ::ZMQ::POLLOUT, &block
      end

      # Monitor the given ZMQ socket with the given options
      def monitor_zmq(socket, set, type)
        if set.has_key? socket
          raise ArgumentError, "another method is already waiting on #{socket.inspect}"
        else
          set[socket] = Fiber.current
        end

        @poller.register socket, type
        Fiber.yield
        result = block_given? ? yield(socket) : socket
        @poller.deregister socket, type
        result
      end

      # Run the reactor, waiting for events, and calling the given block if
      # the reactor is awoken by the waker
      def run_once
        if @poller.size == 0
          readable, _ = select [@waker.io]
          yield if readable.include? @waker.io
        else
          if ::ZMQ::Util.resultcode_ok? @poller.poll(100)
            @poller.readables.each do |sock|
              fiber = @readers.delete sock
              fiber.resume if fiber
            end

            @poller.writables.each do |sock|
              fiber = @writers.delete sock
              fiber.resume if fiber
            end
          end

          readable, _ = select [@waker.io], [], [], 0
          yield if readable and readable.include? @waker.io
        end
      end
    end
  end
end
