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

Prerequisites
-------------

DCell requires 0MQ. On OS X, this is available through Homebrew by running:

    brew install zeromq

DCell also requires Zookeeper. Before you harumph and bemoan this gargantuan
Java-encrusted dependency, relax and enhance your calm for a second: DCell
totally automates installing and starting Zookeeper.

To install Zookeeper, run:

    rake zookeeper:install

and to start it run:

    rake zookeeper:start

You will need Zookeeper running to do anything, and will need to start a copy
before running the tests (that part isn't automated yet, sorry)

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

All services exposed by DCell must take the form of Celluloid actors. What
follows is an extremely brief introduction, but for more information, you
should definitely [read the Celluloid documentation](http://celluloid.github.com).

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