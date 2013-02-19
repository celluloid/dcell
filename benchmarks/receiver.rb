require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell'
DCell.start :id => 'benchmark_receiver', :addr => 'tcp://127.0.0.1:2043'

class AsyncReceiver
  include Celluloid
  attr_reader :count

  def initialize(n, actor)
    @n, @actor = n, actor
    @count = 0
  end

  def increment
    @count += 1
    @actor.async.complete if @count == @n
    @count
  end
end

class Progenator
  include Celluloid

  def spawn_async_receiver(n, actor)
    AsyncReceiver.new(n, actor)
  end
end

class BenchmarkApplication < Celluloid::SupervisionGroup
  supervise DCell::SupervisionGroup
  supervise Progenator, :as => :progenator
end

BenchmarkApplication.run
