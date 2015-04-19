require 'celluloid'
require 'reel'
require 'celluloid/zmq'
require 'socket'
require 'securerandom'
require 'msgpack'
require 'uri'

Celluloid::ZMQ.init

require 'dcell/version'
require 'dcell/utils'
require 'dcell/resource_manager'
require 'dcell/actor_proxy'
require 'dcell/directory'
require 'dcell/messages'
require 'dcell/sockets'
require 'dcell/server'
require 'dcell/node_manager'
require 'dcell/node'
require 'dcell/global'
require 'dcell/responses'
require 'dcell/mailbox_manager'
require 'dcell/info_service'
require 'dcell/registries/adapter'
require 'dcell/registries/errors'

require 'dcell/celluloid_ext'

# Distributed Celluloid
module DCell
  class NotConfiguredError < RuntimeError; end # Not configured yet

  @lock = Mutex.new
  @actors = Set.new

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_reader :me

    # Configure DCell with the following options:
    #
    # * id: to identify the local node, defaults to hostname
    # * addr: 0MQ address of the local node (e.g. tcp://4.3.2.1:7777)
    # *
    def setup(options = {})
      @registry = nil

      options = Utils::symbolize_keys options

      @lock.synchronize do
        configuration = {
          addr: "tcp://127.0.0.1:*",
          heartbeat_rate: 5,        # How often to send heartbeats (in seconds)
          heartbeat_timeout: 10,    # How soon until a lost heartbeat triggers a node partition (in seconds)
          request_timeout: 10,      # Timeout on waiting for the response (in seconds)
          ttl_rate: 20,             # How often update TTL in the registry (in seconds)
          id: nil,
        }.merge(options)
        configuration_accessors configuration

        raise ArgumentError, "no registry adapter given in config" unless @registry
        @id ||= generate_node_id

        if Celluloid.logger
          # :nocov:
          Celluloid.logger.formatter = proc do |severity, datetime, progname, msg|
            "[#{datetime}][#{severity}][#{@id}] #{msg}\n"
          end
          # :nocov:
        end
      end
    end

    # Returns actors from multiple nodes
    def find(actor)
      Directory.each_with_object([]) do |id, actors|
        node = Directory[id]
        next unless node
        next if node.id == DCell.id
        next unless node.actors.include? actor
        begin
          rnode = Node[node.id] or raise 'Not found'
          rnode.ping 1
          actors << rnode[actor]
        rescue Exception => e
          Logger.warn "Failed to get actor '#{actor}' on node '#{node.id}': #{e}"
          rnode.terminate if rnode rescue nil
        end
      end
    end
    alias_method :[], :find

    # Run the DCell application in the background
    def run!
      Directory[id].actors = local_actors
      DCell::SupervisionGroup.run!
    end

    # Start combines setup and run! into a single step
    def start(options = {})
      setup options
      run!
    end

    ##################################################
    # Internal API
    ##################################################

    # Updates server address of the node
    def addr=(addr)
      @addr = addr
      @me = Node.new @id, @addr, true
      Directory[@id].address = addr
      ObjectSpace.define_finalizer(me, proc {Directory.remove @id})
    end
    alias_method :address=, :addr=

    def add_local_actor(name)
      @lock.synchronize do
        @actors << name.to_sym
      end
    end

    def get_local_actor(name)
      name = name.to_sym
      if @actors.include? name
        return Celluloid::Actor[name]
      end
      nil
    end

    def local_actors
      @actors.to_a
    end

    # Attempt to generate a unique node ID for this machine
    def generate_node_id
      # a little bit more creative
      if @registry.respond_to? :unique
        @registry.unique
      else
        digest = Digest::SHA512.new
        seed = ::Socket.gethostname + rand.to_s + Time.now.to_s + SecureRandom.hex
        digest.update(seed).to_s
      end
    end

    def configuration_accessors(configuration)
      configuration.each do |name, value|
        instance_variable_set "@#{name}", value
        self.class.class_eval do
          undef_method name rescue nil
          attr_reader name
        end
      end
      self.class.class_eval do
        alias_method :address, :addr
      end
    end
  end

  extend ClassMethods

  # DCell's actor dependencies
  class SupervisionGroup < Celluloid::SupervisionGroup
    supervise RequestServer, as: :server
    supervise InfoService, as: :info
  end
  DCell.add_local_actor :info

  Logger = Celluloid::Logger
end
