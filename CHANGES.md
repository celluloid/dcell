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
