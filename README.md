DCell
=====

Distributed Celluloid based on 0MQ! Stay tuned!

Prerequisites
-------------

DCell requires 0MQ. On OS X, this is available through Homebrew by running:

  brew install zeromq

DCell also requires Zookeeper. For production, you will need to install and
maintain your own Zookeeper cluster. For development, you can run the
following to download and install Zookeeper:

  rake zookeeper:install
