require 'weakref'

module DCell
  EPOCH = Time.gm(2012) # All things begin in 2012

  class RPC < Celluloid::SyncCall
    def initialize(id, caller, method, arguments, block)
      @id, @caller, @method, @arguments, @block = id, caller, method, arguments, block
    end

    # Custom marshaller for compatibility with Celluloid::Mailbox marshalling
    def _dump(level)
      payload = Marshal.dump [@caller, @method, @arguments, @block]
      "#{@id}:#{payload}"
    end

    # Loader for custom marshal format
    def self._load(string)
      id = string.slice!(0, string.index(":") + 1)
      match = id.match(/^([0-9a-fA-F]+)@(.+?):$/)
      raise ArgumentError, "couldn't parse call ID" unless match

      call_id, node_id = match[1], match[2]

      if DCell.id == node_id
        Manager.claim Integer("0x#{call_id}")
      else
        caller, method, arguments, block = Marshal.load(string)
        RPC.new("#{call_id}@#{node_id}", caller, method, arguments, block)
      end
    end

    # Tracks calls-in-flight
    class Manager
      @mutex  = Mutex.new
      @ids    = {}
      @calls  = {}
      @serial = Integer(Time.now - EPOCH) * 0x100000

      def self.register(call)
        @mutex.lock
        call_id = @ids[call.object_id]
        unless call_id
          call_id = @serial
          @serial += 1
          @ids[call.object_id] = call_id
        end

        @calls[call_id] = WeakRef.new(call)
        call_id
      ensure
        @mutex.unlock
      end

      def self.claim(call_id)
        @mutex.lock
        ref = @calls.delete(call_id)
        ref.__getobj__ if ref
      rescue WeakRef::RefError
        # Nothing to see here, folks
      ensure
        @mutex.unlock
      end
    end
  end
end
