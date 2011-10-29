DCell
=====

Distributed Celluloid based on 0MQ! Stay tuned!

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