# Celluloid mailboxes are the universal message exchange points. You won't
# be able to marshal them though, unfortunately, because they contain
# mutexes.
#
# DCell provides a message routing layer between nodes that can direct
# messages back to local mailboxes. To accomplish this, DCell adds custom
# marshalling to mailboxes so that if they're unserialized on a remote
# node you instead get a proxy object that routes messages through the
# DCell overlay network back to the node where the actor actually exists

module DCell
  # Proxy object for actors that live on remote nodes
  # This subclass serves as a marker this is a DCell-based proxy
  class ActorProxy < Celluloid::ActorProxy; end
end

module Celluloid
  class ActorProxy
    # Marshal uses respond_to? to determine if this object supports _dump so
    # unfortunately we have to monkeypatch in _dump support as the proxy
    # itself normally jacks respond_to? and proxies to the actor
    alias_method :__respond_to?, :respond_to?
    def respond_to?(meth)
      return true if meth == :_dump
      __respond_to? meth
    end

    # Dump an actor proxy via its mailbox
    def _dump(level)
      @mailbox._dump(level)
    end

    # Create an actor proxy object which routes messages over DCell's overlay
    # network and back to the original mailbox
    def self._load(string)
      DCell::ActorProxy.new Celluloid::Mailbox._load(string)
    end
  end

  class Mailbox
    # This custom dumper registers actors with the DCell registry so they can
    # be reached remotely.
    def _dump(level)
      mailbox_id = DCell::Registry.register self
      "#{mailbox_id}@#{DCell.id}"
    end

    # Create a mailbox proxy object which routes messages over DCell's overlay
    # network and back to the original mailbox
    def self._load(string)
      mailbox_id, node_id = string.split("@")
      DCell::MailboxProxy.new(node_id, mailbox_id)
    end
  end
end
