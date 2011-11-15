require 'celluloid'
require 'celluloid/zmq'

require 'dcell/version'
require 'dcell/directory'
require 'dcell/mailbox_proxy'
require 'dcell/messages'
require 'dcell/node'
require 'dcell/global'
require 'dcell/responses'
require 'dcell/router'
require 'dcell/server'

require 'dcell/registries/zookeeper_adapter'
require 'dcell/registries/redis_adapter'
require 'dcell/application'
require 'dcell/celluloid_ext'

# Distributed Celluloid
module DCell
  DEFAULT_PORT  = 7777 # Default DCell port
  ZMQ_POOL_SIZE = 1 # DCell uses a fixed-size 0MQ thread pool
  @zmq_context  = ::ZMQ::Context.new(ZMQ_POOL_SIZE)
  @config_lock  = Mutex.new

  class << self
    attr_reader :me, :registry, :zmq_context

    # Configure DCell with the following options:
    #
    # * id: to identify the local node, defaults to hostname
    # * addr: 0MQ address of the local node (e.g. tcp://4.3.2.1:7777)
    # *
    def setup(options = {})
      # Stringify keys :/
      options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

      @config_lock.synchronize do
        @configuration = {
          'id'   => generate_node_id,
          'addr' => "tcp://127.0.0.1:#{DEFAULT_PORT}",
          'registry' => {'adapter' => 'zk', 'server' => 'localhost'}
        }.merge(options)

        @me = Node.new @configuration['id'], @configuration['addr']

        if @configuration['registry'] and @configuration['registry']['adapter'] == 'zk'
          @registry = ZookeeperAdapter.new(@configuration['registry'])
        else raise "invalid registry adapter"
        end

        DCell::Directory.set @configuration['id'], @configuration['addr']
      end

      me
    end

    # Obtain the local node ID
    def id; @configuration['id']; end

    # Obtain the 0MQ address to the local mailbox
    def addr; @configuration['addr']; end
    alias_method :address, :addr

    # Attempt to generate a unique node ID for this machine
    def generate_node_id
      `hostname`.strip # Super creative I know
    end

    # Run the DCell application
    def run
      DCell::Application.run
    end

    # Run the DCell application in the background
    def run!
      DCell::Application.run!
    end
  end
end
