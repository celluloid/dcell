#!/usr/bin/env ruby

require 'benchmark'

require 'dcell'
require 'dcell/registries/redis_adapter'

DCell.start id: 'benchmark_messaging',
            registry: DCell::Registry::RedisAdapter.new

$receiver_pid = Process.spawn Gem.ruby, File.expand_path("../receiver.rb", __FILE__)

print "Waiting for test node to start up..."

receiver = nil
30.times do
  begin
    receiver = DCell::Node['benchmark_receiver']
    receiver.ping 1
    break
  rescue => e
    print "."
    receiver = nil
    sleep 1
  end
end

if receiver
  puts " done!"
else
  puts " FAILED!"
  raise "couldn't connect to test node!"
end

class AsyncPerformanceTest
  include Celluloid

  attr_reader :n

  def initialize(n, receiver)
    @n = n
    @receiver = receiver
  end

  def run
    @n.times { @receiver.async.increment }
    wait :complete
  end

  def complete
    signal :complete
  end
end

class AsyncSender
  include Celluloid

  attr_accessor :test

  def initialize
    @test = nil
  end

  def complete
    @test.complete
  end
end
AsyncSender.supervise_as :sender

count = 10_000

receiver[:progenator].spawn_async_receiver(count, DCell.id, :sender)

test = AsyncPerformanceTest.new count, receiver[:receiver]
Celluloid::Actor[:sender].test = test

time = Benchmark.measure { test.run }.real
messages_per_second = 1 / time * count

puts "messages_per_second: #{"%0.2f" % messages_per_second}"

Process.kill 9, $receiver_pid
Process.wait $receiver_pid rescue nil

exit 0
