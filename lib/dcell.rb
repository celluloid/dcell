require 'celluloid'
require 'reel'
require 'celluloid/zmq'
require 'socket'
require 'securerandom'

Celluloid::ZMQ.init

require 'dcell/version'
require 'dcell/actor_proxy'
require 'dcell/directory'
require 'dcell/mailbox_proxy'
require 'dcell/messages'
require 'dcell/node'
require 'dcell/node_manager'
require 'dcell/global'
require 'dcell/responses'
require 'dcell/router'
require 'dcell/rpc'
require 'dcell/future_proxy'
require 'dcell/server'
require 'dcell/info_service'

require 'dcell/registries/redis_adapter'

require 'dcell/celluloid_ext'

# Distributed Celluloid
module DCell
  class NotConfiguredError < RuntimeError; end # Not configured yet

  @config_lock  = Mutex.new

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_reader :me, :registry

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
          'addr' => "tcp://127.0.0.1:*",
          'registry' => {'adapter' => 'redis', 'server' => 'localhost'}
        }.merge(options)

        registry_adapter = @configuration['registry'][:adapter] || @configuration['registry']['adapter']
        raise ArgumentError, "no registry adapter given in config" unless registry_adapter

        registry_class_name = registry_adapter.split("_").map(&:capitalize).join << "Adapter"

        begin
          registry_class = DCell::Registry.const_get registry_class_name
        rescue NameError
          raise ArgumentError, "invalid registry adapter: #{registry_adapter}"
        end

        @registry = registry_class.new(@configuration['registry'])
        @configuration['id'] ||= generate_node_id
        @me = Node.new @configuration['id'], nil
        ObjectSpace.define_finalizer(me, proc {Directory.remove @configuration['id']})
      end

      me
    end

    # Obtain the local node ID
    def id
      unless @configuration
        Logger.warn "DCell unconfigured"
        return nil
      end
      @configuration['id']
    end

    # Obtain the 0MQ address to the local mailbox
    def addr; @configuration['addr']; end
    alias_method :address, :addr

    def addr=(addr)
      @configuration['addr'] = addr
      Directory.set @configuration['id'], addr
      @me.update_server_address addr
    end
    alias_method :address=, :addr=

    # Attempt to generate a unique node ID for this machine
    def generate_node_id
      # a little bit more creative
      if @registry.respond_to? :unique
        @registry.unique
      else
        digest = Digest::SHA512.new
        seed = Socket.gethostname + rand.to_s + Time.now.to_s + SecureRandom.hex
        digest.update(seed).to_s
      end
    end

    # Run the DCell application in the background
    def run!
      DCell::SupervisionGroup.run!
    end

    # Start combines setup and run! into a single step
    def start(options = {})
      setup options
      run!
    end
  end
  extend ClassMethods

  # DCell's actor dependencies
  class SupervisionGroup < Celluloid::SupervisionGroup
    supervise NodeManager, :as => :node_manager
    supervise Server,      :as => :dcell_server, :args => [DCell]
    supervise InfoService, :as => :info
  end

  Logger = Celluloid::Logger
end
