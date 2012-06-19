# Celluloid mailboxes are the universal message exchange points. You won't
# be able to marshal them though, unfortunately, because they contain
# mutexes.
#
# DCell provides a message routing layer between nodes that can direct
# messages back to local mailboxes. To accomplish this, DCell adds custom
# marshalling to mailboxes so that if they're unserialized on a remote
# node you instead get a proxy object that routes messages through the
# DCell overlay network back to the node where the actor actually exists

module Celluloid
  class ActorProxy
    # Marshal uses respond_to? to determine if this object supports _dump so
    # unfortunately we have to monkeypatch in _dump support as the proxy
    # itself normally jacks respond_to? and proxies to the actor
    alias_method :__respond_to?, :respond_to?
    def respond_to?(meth)
      return false if meth == :marshal_dump
      return true  if meth == :_dump
      __respond_to? meth
    end

    # Dump an actor proxy via its mailbox
    def _dump(level)
      @mailbox._dump(level)
    end

    # Create an actor proxy object which routes messages over DCell's overlay
    # network and back to the original mailbox
    def self._load(string)
      mailbox = Celluloid::Mailbox._load(string)

      case mailbox
      when DCell::MailboxProxy
        actor = DCell::Actor.new(mailbox)
        DCell::ActorProxy.new actor
      when Celluloid::Mailbox
        actor = find_actor(mailbox)
        Celluloid::ActorProxy.new(actor)
      else raise "funny, I did not expect to see a #{mailbox.class} here"
      end
    end

    def self.find_actor(mailbox)
      Thread.list.each do |t|
        if actor = t[:actor]
          return actor if actor.mailbox == mailbox
        end
      end
      raise "no actor found for mailbox: #{mailbox.inspect}"
    end
  end

  class Mailbox
    # This custom dumper registers actors with the DCell registry so they can
    # be reached remotely.
    def _dump(level)
      mailbox_id = DCell::Router.register self
      "#{mailbox_id}@#{DCell.id}@#{DCell.addr}"
    end

    # Create a mailbox proxy object which routes messages over DCell's overlay
    # network and back to the original mailbox
    def self._load(string)
      DCell::MailboxProxy._load(string)
    end
  end

  class SyncCall
    def _dump(level)
      uuid = DCell::RPC::Manager.register self
      payload = Marshal.dump([@caller,@method,@arguments,@block])
      "#{uuid}@#{DCell.id}:#{payload}"
    end

    def self._load(string)
      DCell::RPC._load(string)
    end
  end

  class Future
    def _dump(level)
      mailbox_id = DCell::Router.register self
      "#{mailbox_id}@#{DCell.id}@#{DCell.addr}"
    end

    def self._load(string)
      DCell::FutureProxy._load(string)
    end
  end
end
