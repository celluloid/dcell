DCell
=====

DCell is a simple and easy way to build distributed applications in Ruby.
Somewhat similar to DRb, DCell lets you easily expose Ruby objects as network
services, and call them remotely just like you would any other Ruby object.
However, unlike DRb all objects in the system are concurrent. You can create
and register several available services on a given node, obtain handles to
them, and easily pass these handles around the network just like any other
objects.

DCell is a distributed extension to Celluloid, which provides concurrent
objects for Ruby with many of the features of Erlang, such as the ability
to supervise objects and restart them when they crash, and also link to
other objects and receive event notifications of when they crash. This makes
it easier to build robust, fault-tolerant distributed systems.

You can read more about Celluloid at: http://celluloid.github.com

Supported Platforms
-------------------

DCell works on Ruby 1.9.2/1.9.3, JRuby 1.6 (in 1.9 mode), and Rubinius 2.0.

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line
option to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment
variable:

    export JRUBY_OPTS=--1.9

(Note: I'd recommend putting the above in your .bashrc/.zshrc/etc in
general. 1.9 is the future, time to embrace it)

Celluloid works on Rubinius in either 1.8 or 1.9 mode.

All components, including the 0MQ bindings, Redis, and Zookeeper adapters
are all certified to work on the above platforms. The 0MQ binding is FFI.
The Redis adapter is pure Ruby. The Zookeeper adapter uses an MRI-style
native extension but also supplies a pure-Java backend for JRuby.

Prerequisites
-------------

DCell requires 0MQ. On OS X, this is available through Homebrew by running:

    brew install zeromq

DCell keeps the state of all connected nodes and global configuration data
in a service it calls the "registry". There are presently two supported
registry services:

* Redis (Fast and Loose): simple and easy to use for development and
  prototyping, but lacks a good distribution story

* Zookeeper (Serious Business): has slightly more annoying client-side
  dependencies and more difficult to deploy than Redis, but has rock
  solid characteristics in a distributed scenario

You may pick either one of these services to use as DCell's registry. The
default is Redis.

To install a local copy of Redis on OS X with Homebrew, run:

    brew install redis

To install a local copy Zookeeper for testing purposes, run:

    rake zookeeper:install

and to start it run:

    rake zookeeper:start

Usage
-----

The fastest way to start up a DCell node is to start Zookeeper (see above)
then run the following in Ruby:

    require 'dcell'

    DCell.setup
    DCell.run!

The call to DCell.setup configures DCell (in this case with the default
settings). The call to DCell.run! starts the services DCell needs to operate
in a background thread. If you'd like to run multiple nodes on the same
computer you'll need to give each node a unique name and port number.
To do this pass the following to DCell.setup:

    DCell.setup :id => "node42", :addr => "tcp://127.0.0.1:2042"

To join a cluster you'll need to provide the location of the registry server.
This can be done through the "registry" key:

	DCell.setup :id => "node24", :addr => "tcp://127.0.0.1:2042", :registry => {
	  :adapter => 'redis',
	  :host    => 'mycluster.example.org',
	  :port    => 6379
	}

When configuring DCell to use Redis, use the following options:

- **adapter**: "redis" (*optional, alternatively "zk"*)
- **host**: hostname or IP address of the Redis server (*optional, default localhost*)
- **port**: port of the Redis server (*optional, default 6379*)
- **password**: password to the Redis server (*optional*)

You've now configured a single node in a DCell cluster. This node is identified
by a unique id, which defaults to your hostname. You can obtain the DCell::Node
object representing the local node by calling DCell.me:

    >> DCell.setup
     => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">
    >> DCell.run!
     => #<Celluloid::Supervisor(DCell::Application):0xed6>
    >> DCell.me
     => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">

DCell::Node objects are the entry point for locating actors on the system.
DCell.me returns the local node. Other nodes can be obtained by their
node IDs:

    >> node = DCell::Node["cryptosphere.local"]
     => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">

DCell::Node.all returns all connected nodes in the cluster:

    >> DCell::Node.all
     => [#<DCell::Node[test_node] @addr="tcp://127.0.0.1:21264">, #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">]

Once you've obtained a node, you can look up services it exports and call them
just like you'd invoke methods on any other Ruby object:

    >> time_server = node[:time_server]
     => #<Celluloid::Actor(TimeServer:0xee8)>
    >> time_server.time
     => "The time is: 2011-11-10 20:23:47 -0800"

Registering Actors
------------------

All services exposed by DCell must take the form of registered Celluloid actors.
What follows is an extremely brief introduction to creating and registering
actors, but for more information, you should definitely [read the Celluloid
documentation](http://celluloid.github.com).

DCell exposes all Celluloid actors you've registered directly onto the network.
The best way to register an actor is by supervising it. Below is an example of
how to create an actor and register it on the network:

    class TimeServer
      include Celluloid

      def time
        "The time is: #{Time.now}"
      end
    end

Now that we've defined the TimeServer, we're going to supervise it and register
it in the local registry:

	>> TimeServer.supervise_as :time_server
	 => #<Celluloid::Supervisor(TimeServer):0xee4>

Supervising actors means that if they crash, they're automatically restarted
and registered under the same name. We can access registered actors by using
Celluloid::Actor#[]:

	>> Celluloid::Actor[:time_server]
	 => #<Celluloid::Actor(TimeServer:0xee8)>
	>> Celluloid::Actor[:time_server].time
	 => "The time is: 2011-11-10 20:17:48 -0800"

This same actor is now available using the DCell::Node#[] syntax:

    >> node = DCell.me
     => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:1870">
    >> node[:time_server].time
     => "The time is: 2011-11-10 20:28:27 -0800"

Globals
-------

DCell provides a registry global for storing configuration data and actors you
wish to publish globally to the entire cluster:

	>> actor = Celluloid::Actor[:dcell_server]
	 => #<Celluloid::Actor(DCell::Server:0xf2e) @addr="tcp://127.0.0.1:7777">
	>> DCell::Global[:sweet_server] = actor
	 => #<Celluloid::Actor(DCell::Server:0xf2e) @addr="tcp://127.0.0.1:7777">
	>> DCell::Global[:sweet_server]
	 => #<Celluloid::Actor(DCell::Server:0xf2e) @addr="tcp://127.0.0.1:7777">
