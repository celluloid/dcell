module DCell
  module ZMQ
    # A Celluloid mailbox for Actors that wait on 0MQ sockets
    class Mailbox < Celluloid::IO::Mailbox
      attr_reader :reactor, :waker

      def initialize
        @messages = []
        @lock  = Mutex.new
        @waker = Celluloid::IO::Waker.new
        @reactor = Reactor.new(@waker)
      end
    end
  end
end