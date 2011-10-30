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
