require 'dcell'
require 'dcell/registries/redis_adapter'

DCell.start id: 'benchmark_receiver',
            registry: DCell::Registry::RedisAdapter.new

class AsyncReceiver
  include Celluloid

  attr_reader :count

  def initialize(n, node, actor)
    @n, @actor = n, DCell::Node[node][actor.to_sym]
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

  def spawn_async_receiver(n, node, actor)
    AsyncReceiver.supervise_as :receiver, args: [n, node, actor]
    nil
  end
end
Progenator.supervise_as :progenator

sleep
