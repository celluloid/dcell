![DCell](https://github.com/celluloid/dcell/raw/master/logo.png)
=====
[![Build Status](http://travis-ci.org/celluloid/dcell.png)](http://travis-ci.org/celluloid/dcell)
[![Dependency Status](https://gemnasium.com/celluloid/dcell.png)](https://gemnasium.com/celluloid/dcell)

> "Objects can message objects transparently that live on other machines
> over the network, and you don't have to worry about the networking gunk,
> and you don't have to worry about finding them, and you don't have to
> worry about anything. It's just as if you messaged an object that's
> right next door."
> _--Steve Jobs describing the NeXT Portable Distributed Object system_

DCell is a simple and easy way to build distributed applications in Ruby.
Somewhat similar to DRb, DCell lets you easily expose Ruby objects as network
services, and call them remotely just like you would any other Ruby object.
However, unlike DRb all objects in the system are concurrent. You can create
and register several available services on a given node, obtain handles to
them, and easily pass these handles around the network just like any other
objects.

DCell is a distributed extension to [Celluloid][celluloid], which provides
concurrent objects for Ruby with many of the features of Erlang, such as the
ability to supervise objects and restart them when they crash, and also link to
other objects and receive event notifications of when they crash. This makes
it easier to build robust, fault-tolerant distributed systems.

DCell uses the [0MQ][zeromq] messaging protocol which provides a robust,
fault-tolerant brokerless transport for asynchronous messages sent between
nodes. DCell is built on top of the [Celluloid::ZMQ][celluloid-zmq] library,
which provides a Celluloid-oriented wrapper around the underlying
[ffi-rzmq][ffi-rzmq] library.

Like DCell? [Join the Celluloid Google Group][googlegroup]

[celluloid]: http://celluloid.io/
[zeromq]: http://www.zeromq.org/
[celluloid-zmq]: https://github.com/celluloid/celluloid-zmq
[ffi-rzmq]: https://github.com/chuckremes/ffi-rzmq
[googlegroup]: http://groups.google.com/group/celluloid-ruby

### Is It Good?

Yes.

### Is It "Production Ready™"?

Not entirely, but eager early adopters are welcome!

Supported Platforms
-------------------

DCell works on Ruby 1.9.2/1.9.3, JRuby 1.6 (in 1.9 mode), JRuby 1.7, and Rubinius 2.0.

To use JRuby 1.6 in 1.9 mode, you'll need to pass the "--1.9" command line
option to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment
variable:

    export JRUBY_OPTS=--1.9

(Note: I'd recommend putting the above in your .bashrc/.zshrc/etc in
general. 1.9 is the future, time to embrace it)

To use JRuby 1.7 in 1.9 mode...just use it :)

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
in a service it calls the "registry". DCell supports any of the following for
use as registries:

* **Redis**: a persistent data structures server. It's simple and easy to use
  for development and prototyping, but lacks a good distribution story.

* **Zookeeper**: Zookeeper is a high-performance coordination service for
  distributed applications. It exposes common services such as naming,
  configuration management, synchronization, and group management.
  Unfortunately, it has slightly more annoying client-side dependencies and is
  more difficult to deploy than Redis.

* **Cassandra**: a distributed database with no single points of
  failure and can store huge amounts of data. Setup requires creating a
  keyspace and defining a single column family before staring DCell. The
  Cassandra backend defaults to a keyspace/CF both named "dcell". There
  are two rows, "nodes" and "globals" each with one column per entry.

You may pick any of these services to use as DCell's registry. The
default is Redis.

To install a local copy of Redis on OS X with Homebrew, run:

    brew install redis

To install a local copy Zookeeper for testing purposes, run:

    rake zookeeper:install

and to start it run:

    rake zookeeper:start

To install a local copy Apache Cassandra for testing purposes, run:

    rake cassandra:install
    rake cassandra:start

Configuration
-------------

The simplest way to configure and start DCell is with the following:

```ruby
require 'dcell'

DCell.start
```

This configures DCell with all the default options, however there are many
options you can override, e.g.:

```ruby
DCell.start :id => "node42", :addr => "tcp://127.0.0.1:2042"
```

DCell identifies each node with a unique node ID, that defaults to your
hostname. Each node needs to be reachable over 0MQ, and the addr option
specifies the 0MQ address where the host can be reached. When giving a tcp://
URL, you *must* specify an IP address and not a hostname.

To join a cluster you'll need to provide the location of the registry server.
This can be done through the "registry" configuration key:

```ruby
DCell.start :id => "node24", :addr => "tcp://127.0.0.1:2042",
  :registry => {
    :adapter => 'redis',
    :host    => 'mycluster.example.org',
    :port    => 6379
  }
```

When configuring DCell to use Redis, use the following options:

- **adapter**: "redis" (*optional, alternatively "zk"*)
- **host**: hostname or IP address of the Redis server (*optional, default localhost*)
- **port**: port of the Redis server (*optional, default 6379*)
- **password**: password to the Redis server (*optional*)

Usage
-----

You've now configured a single node in a DCell cluster. You can obtain the
DCell::Node object representing the local node by calling DCell.me:

```ruby
>> DCell.start
 => #<Celluloid::Supervisor(DCell::Application):0xed6>
>> DCell.me
 => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">
```

DCell::Node objects are the entry point for locating actors on the system.
DCell.me returns the local node. Other nodes can be obtained by their
node IDs:

```ruby
>> node = DCell::Node["cryptosphere.local"]
 => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">
```

DCell::Node.all returns all connected nodes in the cluster:

```ruby
>> DCell::Node.all
 => [#<DCell::Node[test_node] @addr="tcp://127.0.0.1:21264">, #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">]
```

DCell::Node is a Ruby Enumerable. You can iterate across all nodes with
DCell::Node.each.

Once you've obtained a node, you can look up services it exports and call them
just like you'd invoke methods on any other Ruby object:

```ruby
>> node = DCell::Node["cryptosphere.local"]
 => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">
>> time_server = node[:time_server]
 => #<Celluloid::Actor(TimeServer:0xee8)>
>> time_server.time
 => "The time is: 2011-11-10 20:23:47 -0800"
```

You can also find all available services on a node with DCell::Node#all:

```ruby
>> node = DCell::Node["cryptosphere.local"]
 => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:7777">
>> node.all
 => [:time_server]
```

Registering Actors
------------------

All services exposed by DCell must take the form of registered Celluloid actors.
What follows is an extremely brief introduction to creating and registering
actors, but for more information, you should definitely [read the Celluloid
documentation](http://celluloid.github.com).

DCell exposes all Celluloid actors you've registered directly onto the network.
The best way to register an actor is by supervising it. Below is an example of
how to create an actor and register it on the network:

```ruby
class TimeServer
  include Celluloid

  def time
    "The time is: #{Time.now}"
  end
end
```

Now that we've defined the TimeServer, we're going to supervise it and register
it in the local registry:

```ruby
>> TimeServer.supervise_as :time_server
 => #<Celluloid::Supervisor(TimeServer):0xee4>
```

Supervising actors means that if they crash, they're automatically restarted
and registered under the same name. We can access registered actors by using
Celluloid::Actor#[]:

```ruby
>> Celluloid::Actor[:time_server]
 => #<Celluloid::Actor(TimeServer:0xee8)>
>> Celluloid::Actor[:time_server].time
 => "The time is: 2011-11-10 20:17:48 -0800"
```

This same actor is now available using the DCell::Node#[] syntax:

```ruby
>> node = DCell.me
 => #<DCell::Node[cryptosphere.local] @addr="tcp://127.0.0.1:1870">
>> node[:time_server].time
 => "The time is: 2011-11-10 20:28:27 -0800"
```

Globals
-------

DCell provides a registry global for storing configuration data and actors you
wish to publish globally to the entire cluster:

```ruby
>> actor = Celluloid::Actor[:dcell_server]
 => #<Celluloid::Actor(DCell::Server:0xf2e) @addr="tcp://127.0.0.1:7777">
>> DCell::Global[:sweet_server] = actor
 => #<Celluloid::Actor(DCell::Server:0xf2e) @addr="tcp://127.0.0.1:7777">
>> DCell::Global[:sweet_server]
 => #<Celluloid::Actor(DCell::Server:0xf2e) @addr="tcp://127.0.0.1:7777">
```

What about DRb?
---------------

Ruby already has a distributed object system as part of its standard library:
DRb, which stands for Distributed Ruby. What's wrong with DRb? Why do we need
a new system? DRb has one major drawback: it's inherently synchronous. The
only thing you can do to an object is to make a method call, which sends a
remote object a message, executes the method, and returns a response.

Under the covers, DCell uses an asynchronous message protocol. As noted in the
last section, asynchronous messaging allows many more modes of messaging than
the standard reqeust/response pattern afforded by DRb. DCell also supports the
Erlang-style approach to fault-tolerance, advocating that actors shouldn't handle
errors but should crash and restart in a clean state. Linking to actors on remote
nodes can be used to detect these sorts of errors and have dependent actors
restart in a clean state.

By far the biggest difference between DCell and DRb is how the underlying
Celluloid framework has you think about the problem. Celluloid provides a useful
concurrent in-process messaging system in its own right without the distributed
components.

Copyright
---------

Copyright (c) 2012 Tony Arcieri. See LICENSE.txt for further details.
