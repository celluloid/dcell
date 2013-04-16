require 'weakref'

module DCell
  class RPB < Celluloid::BlockProxy
    def initialize(id, mailbox, execution, arguments)
      @id, @mailbox, @execution, @arguments = id, mailbox, execution, arguments
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump [@mailbox, @execution, @arguments]
      "#{@id}:rpb:#{payload}"
    end
  end

  class RPBC < Celluloid::BlockCall
    def initialize(id, block_proxy, sender, arguments)
      @id, @block_proxy, @sender, @arguments = id, block_proxy, sender, arguments
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump [@block_proxy, @sender, @arguments]
      "#{@id}:rpbc:#{payload}"
    end
  end

  class RPC < Celluloid::SyncCall
    def initialize(id, sender, method, arguments, block)
      @id, @sender, @method, @arguments, @block = id, sender, method, arguments, block
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump [@sender, @method, @arguments, @block]
      "#{@id}:rpc:#{payload}"
    end

    # Loader for custom marshal format
    def self._load(string)
      id = string.slice!(0, string.index(":") + 1)
      match = id.match(/^([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})@(.+?):$/)
      raise ArgumentError, "couldn't parse call ID" unless match

      uuid, node_id = match[1], match[2]

      if DCell.id == node_id
        Manager.claim uuid
      else
        type = string.slice!(0, string.index(":") + 1)
        types = {
          "rpc" => RPC,
          "rpb" => RPB,
          "rpbc" => RPBC,
        }
        types.fetch(type[0..-2]).new("#{uuid}@#{node_id}", *Marshal.load(string))
      end
    end

    # Tracks calls-in-flight
    class Manager
      @mutex  = Mutex.new
      @ids    = {}
      @calls  = {}

      def self.register(call)
        @mutex.lock
        begin
          call_id = @ids[call.object_id]
          unless call_id
            call_id = Celluloid.uuid
            @ids[call.object_id] = call_id
          end

          @calls[call_id] = WeakRef.new(call)
          call_id
        ensure
          @mutex.unlock rescue nil
        end
      end

      def self.claim(call_id)
        @mutex.lock
        begin
          ref = @calls.delete(call_id)
          ref.__getobj__ if ref
        rescue WeakRef::RefError
          # Nothing to see here, folks
        ensure
          @mutex.unlock rescue nil
        end
      end
    end
  end
end
