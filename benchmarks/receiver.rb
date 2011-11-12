require 'rubygems'
require 'bundler'
Bundler.setup

require 'dcell'
DCell.setup :id => 'benchmark_receiver', :addr => 'tcp://127.0.0.1:12345'

class AsyncReceiver
  include Celluloid
  attr_reader :count

  def initialize(n, actor)
    @n, @actor = n, actor
    @count = 0
  end

  def increment
    @count += 1
    @actor.complete! if @count == @n
    @count
  end
end

class Progenator
  include Celluloid

  def spawn_async_receiver(n, actor)
    AsyncReceiver.new(n, actor)
  end
end

class BenchmarkApplication < Celluloid::Application
  supervise DCell::Application
  supervise Progenator, :as => :progenator
end

BenchmarkApplication.run
