require 'dcell'

Dir['./spec/options/*.rb'].map { |f| require f }

DCell.start test_options

module TestNode
  def self.start
    @pid = Process.spawn Gem.ruby, File.expand_path("./spec/test_node_wrap.rb")
    unless @pid
      STDERR.print "ERROR: Couldn't start test node."
      exit 1
    end
  end

  def self.wait_until_ready
    STDERR.print "Waiting for test node to start up..."

    node = nil
    60.times do
      begin
        node = DCell::Node[TEST_NODE[:id]]
        break if node
        STDERR.print "."
        sleep 1
      end
    end

    if node
      STDERR.puts " done!"
    else
      STDERR.puts " FAILED!"
      raise "couldn't connect to test node!"
    end
  end

  def self.stop
    unless @pid
      STDERR.print "ERROR: Test node was never started!"
      raise "no test node process found"
    end
    Process.kill :TERM, @pid
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
