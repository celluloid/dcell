#!/usr/bin/env ruby

require 'benchmark'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell'
DCell.setup
DCell.run!

RECEIVER_PORT = 12345

$receiver_pid = Process.spawn Gem.ruby, File.expand_path("../receiver.rb", __FILE__)
STDERR.print "Waiting for test node to start up..."

socket = nil
30.times do
  begin
    socket = TCPSocket.open("127.0.0.1", RECEIVER_PORT)
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

class AsyncPerformanceTest
  include Celluloid

  def initialize(progenator, n = 10000)
    @n = n
    @receiver = progenator.spawn_async_receiver(n, current_actor)
  end

  def run
    @n.times { @receiver.increment! }
    wait :complete
  end

  def complete
    signal :complete
  end
end

receiver = DCell::Node['benchmark_receiver']
progenator = receiver[:progenator]

test = AsyncPerformanceTest.new progenator
time = Benchmark.measure { test.run }.real
messages_per_second = 1 / time * 10000

puts "messages_per_second: #{"%0.2f" % messages_per_second}"

Process.kill 9, $receiver_pid
Process.wait $receiver_pid rescue nil

exit 0
