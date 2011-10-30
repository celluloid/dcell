module Celluloid
  module ZMQ
    # React to incoming 0MQ and Celluloid events. This is kinda sorta supposed
    # to resemble the Reactor design pattern.
    class Reactor
      def initialize(waker)
        @waker = waker
        @poller = ::ZMQ::Poller.new

        # Wake up the poller when the mailbox's waker is readable
        # This is broken for whatever reason :(
        #@poller.register nil, ::ZMQ::POLLIN, @waker.io.fileno
      end

      # Wait for the given ZMQ socket to become readable
      def wait_readable(socket, &block)
        monitor socket, ::ZMQ::POLLIN, &block
      end

      # Wait for the given ZMQ socket to become writeable
      def wait_writeable(socket, &block)
        monitor socket, ::ZMQ::POLLOUT, &block
      end

      # Monitor the given ZMQ socket with the given options
      def monitor(socket, type)
        @poller.register @socket, type
        Fiber.yield
        result = block_given? ? yield(io) : io
        @poller.unregister @socket
        result
      end

      # Run the reactor, waiting for events, and calling the given block if
      # the reactor is awoken by the waker
      def run_once
        # Also broken ;(
        #puts "POLLING!"
        #result = @poller.poll :blocking
        #puts "result: #{result}"

        readable, _ = select [@waker.io]
        yield if readable.include? @waker.io
      end
    end
  end
end
