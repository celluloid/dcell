require 'celluloid'
require 'ffi-rzmq'
require 'digest/sha1'

require 'dcell/version'
require 'dcell/server'
require 'dcell/directory'

require 'dcell/adapters/zookeeper_adapter'
# Distributed Celluloid
module DCell
  ZMQ_POOL_SIZE = 1 # DCell uses a fixed-size 0MQ thread pool
  @zmq_context = ZMQ::Context.new(ZMQ_POOL_SIZE)

  class << self
    attr_reader :zmq_context
    attr_reader :configuration

    # Configure DCell
    def setup(options = {})
      # Stringify keys :/
      options = options.inject({}) { |h,(k,v)| h[k.to_s] = v; h }

      @configuration = {
        'id' => generate_node_id,
        'directory' => {'adapter' => 'zk', 'server' => 'localhost'}
      }.merge(options)

      DCell::Directory.setup @configuration['directory']
    end

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
  end
end
