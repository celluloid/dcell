require 'celluloid'
require 'ffi-rzmq'
require 'digest/sha1'

require 'dcell/version'
require 'dcell/zmq/mailbox'
require 'dcell/zmq/reactor'

require 'dcell/directory'
require 'dcell/mailbox'

require 'dcell/adapters/zookeeper_adapter'
require 'dcell/application'

# Distributed Celluloid
module DCell
  DEFAULT_PORT  = 1870 # Default DCell port
  ZMQ_POOL_SIZE = 1 # DCell uses a fixed-size 0MQ thread pool
  @zmq_context  = ::ZMQ::Context.new(ZMQ_POOL_SIZE)

  class << self
    attr_reader :zmq_context
    attr_reader :configuration

    # Configure DCell
    def setup(options = {})
      # Stringify keys :/
      options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

      @configuration = {
        'id'   => generate_node_id,
        'addr' => "tcp://127.0.0.1:#{DEFAULT_PORT}",
        'directory' => {'adapter' => 'zk', 'server' => 'localhost'}
      }.merge(options)

      DCell::Directory.setup @configuration['directory']
    end

    # Obtain the local node ID
    def id; configuration['id']; end

    # Obtain the 0MQ address to the local mailbox
    def addr; configuration['addr']; end
    alias_method :address, :addr

    # Attempt to generate a unique node ID for this machine
    def generate_node_id
      mac_addrs = `/sbin/ifconfig -a`.scan(/(([A-Fa-f0-9]{2}:){5}[A-Fa-f0-9]{2})/)
      first_addr = mac_addrs.map { |addr| addr.first }.sort.first

      if first_addr
        Digest::SHA1.hexdigest(first_addr)
      else
        raise "can't automatically generate a node ID (is /sbin/ifconfig working?)"
      end
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
