0.16.0 (2014-09-04)
-------------------
* Timeouts for cell discovery
* Update Explorer to use new Reel API

0.15.0 (2013-09-04)
-------------------
* Tracking release for Celluloid 0.15
* Use the celluloid-redis gem with the Redis adapter

0.14.0 (2013-05-07)
-------------------
* Allow InfoService to run on linux when lsb-release is missing
* Remove broken moneta adapter
* Use ephemeral mode for ZK adapter
* Add support for executing blocks over DCell

0.13.0
------
* First semi-stable release in nearly forever! Yay!
* Rip out the unstable gossip system, replace the original Zookeeper and
  Redis adapters.
* Compatibility fixes with newer versions of the Celluloid suite

0.10.0
------
* DCell::Explorer provides a web UI with Reel
* Info service at DCell::Node#[:info]
* Distributed gossip protocol, now default adapter
* Support for marshaling Celluloid::Futures
* Cassandra registry
* Initial DCell::NodeManager
* celluloid-zmq split out into a separate gem
* Use Celluloid.uuid for mailbox and call IDs

0.9.0
-----
* Use new Celluloid::ZMQ APIs

0.8.0
-----
* Track calls in-flight with DCell::RPC and DCell::RPC::Manager
* Compatibility changes for Celluloid 0.8.0

0.7.1
-----
* Bump version to match Celluloid
* Factor 0MQ bindings into the celluloid-zmq gem
* Heartbeat system for detecting downed nodes

0.0.1
-----
* Initial release
