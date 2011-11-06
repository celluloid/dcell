module DCell
  class Request
    attr_reader :id

    def initialize
      # Memoize the original object ID so it will get marshalled
      @id = object_id
    end
  end

  # Locate a register actor by name on a remote node
  class LookupRequest < Request
    attr_reader :caller, :name

    def initialize(caller, name)
      super()
      @caller, @name = caller, name
    end
  end

  # Send a message to the given recipient
  class MessageRequest < Request
    attr_reader :recipient, :message

    def initialize(recipient, message)
      super()
      @recipient, @message = recipient, message
    end
  end
end
