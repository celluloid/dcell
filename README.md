![DCell](https://github.com/celluloid/dcell/raw/master/logo.png)
=====
[![Gem Version](https://badge.fury.io/rb/dcell.png)](http://rubygems.org/gems/dcell)
[![Build Status](https://secure.travis-ci.org/niamster/dcell.png?branch=master)](http://travis-ci.org/niamster/dcell)
[![Code Climate](https://codeclimate.com/github/niamster/dcell.png)](https://codeclimate.com/github/niamster/dcell)
[![Coverage Status](https://coveralls.io/repos/niamster/dcell/badge.png?branch=master)](https://coveralls.io/r/niamster/dcell)

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

[Please see the DCell Wiki](https://github.com/celluloid/dcell/wiki)
for more detailed documentation and usage notes.

Like DCell? [Join the Celluloid Google Group][googlegroup]

[celluloid]: http://celluloid.io/
[zeromq]: http://www.zeromq.org/
[celluloid-zmq]: https://github.com/celluloid/celluloid-zmq
[ffi-rzmq]: https://github.com/chuckremes/ffi-rzmq
[googlegroup]: http://groups.google.com/group/celluloid-ruby

### Is it any good?

[Yes.](http://news.ycombinator.com/item?id=3067434)

### Is It "Production Ready™"?

Not entirely, but eager early adopters are welcome!

Installation
------------

Add this line to your application's Gemfile:

    gem 'dcell'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dcell

Inside of your Ruby program do:

    require 'dcell'

...to pull it in as a dependency.

Example
-------

Copy and paste this into `itchy.rb` (or run `bundle exec examples/itchy.rb`):

```ruby
require 'dcell'

DCell.start :id => "itchy", :addr => "tcp://127.0.0.1:9001"

class Itchy
  include Celluloid

  def initialize
    puts "Ready for mayhem!"
    @n = 0
  end

  def fight
    @n = (@n % 6) + 1
    if @n <= 3
      puts "Bite!"
    else
      puts "Fight!"
    end
  end
end

Itchy.supervise_as :itchy
sleep
```

You can now launch itchy with:

```
ruby itchy.rb
```

Now copy and paste the following into `scratchy.rb` (also in examples)

```ruby
require 'dcell'

DCell.start :id => "scratchy", :addr => "tcp://127.0.0.1:9002"
itchy_node = DCell::Node["itchy"]

puts "Fighting itchy! (check itchy's output)"

6.times do
  itchy_node[:itchy].fight
  sleep 1
end
```

Now run scratchy side-by-side with itchy. You should see this on itchy:

```
$ bundle exec examples/itchy.rb
Ready for mayhem!
I, [2012-12-25T22:52:45.362355 #74272]  INFO -- : Connected to scratchy
Bite!
Bite!
Bite!
Fight!
Fight!
Fight!
```

This is a basic example how individual DCell::Nodes have registered Celluloid actors which can be accessed remotely by other DCell::Nodes.

Supported Platforms
-------------------

DCell works on Ruby 1.9.3, JRuby 1.6, and Rubinius 2.0.

DCell requires Ruby 1.9 mode on all interpreters. This works out of the
box on MRI/YARV, and requires the following flags elsewhere:

* JRuby: --1.9 command line option, or JRUBY_OPTS=--1.9 environment variable
* rbx: -X19 command line option

Contributing to DCell
-------------------------

* Fork this repository on github
* Make your changes and send me a pull request
* If I like them I'll merge them
* If I've accepted a patch, feel free to ask for commit access

Copyright
---------

Copyright (c) 2012 Tony Arcieri. Distributed under the MIT License.
See LICENSE.txt for further details.
