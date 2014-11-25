Dir['./spec/options/*.rb'].map { |f| require f }

module TestNode
  def self.start
    @pid = Process.spawn Gem.ruby, File.expand_path("./spec/test_node.rb")
    unless @pid
      STDERR.print "ERROR: Couldn't start test node. Do you have Redis installed?"
      exit 1
    end
  end

  def self.wait_until_ready
    STDERR.print "Waiting for test node to start up..."

    socket = nil
    30.times do
      begin
        socket = TCPSocket.open(TEST_NODE[:addr], TEST_NODE[:port])
        break if socket
      rescue Errno::ECONNREFUSED
        STDERR.print "."
        sleep 1
      end
    end

    if socket
      STDERR.puts " done!"
      socket.close
    else
      STDERR.puts " FAILED!"
      raise "couldn't connect to test node!"
    end
  end

  def self.stop
    unless @pid
      STDERR.print "ERROR: Test node was never started!"
      exit 1
    end
    Process.kill "TERM", @pid
  rescue Errno::ESRCH
  ensure
    Process.wait @pid rescue nil
  end
end

namespace :testnode do
  task :bg do
    TestNode.start
    TestNode.wait_until_ready
  end

  task :finish do
    TestNode.stop
  end
end
