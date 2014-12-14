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
  class Mailbox
    def to_msgpack(pk=nil)
      DCell::Router.register self
      {
        :address => @address,
        :id      => DCell.id
      }.to_msgpack(pk)
    end
  end
end
