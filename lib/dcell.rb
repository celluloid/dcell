require 'celluloid'
require 'ffi-rzmq'

require 'dcell/version'
require 'dcell/server'
require 'dcell/directory'

require 'dcell/adapters/zookeeper_adapter'
# Distributed Celluloid
module DCell
  ZMQ_POOL_SIZE = 1 # DCell uses a fixed-size 0MQ thread pool

  @zmq_context = ZMQ::Context.new(ZMQ_POOL_SIZE)
  def self.zmq_context; @zmq_context; end
end
