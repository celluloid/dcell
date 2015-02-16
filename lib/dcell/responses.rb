module DCell
  # Responses to calls
  class Response
    attr_reader :request_id, :address, :value

    def initialize(request_id, address, value=nil)
      @request_id, @address, @value = request_id, address, value
    end

    def to_msgpack(pk=nil)
      {
        :type => self.class.name,
        :args => [@request_id, @address, @value]
      }.to_msgpack(pk)
    end

    def dispatch
      mailbox = MailboxManager.find @address
      mailbox << self
    end
  end

  # Request successful
  class SuccessResponse < Response; end

  # Request failed
  class ErrorResponse < Response; end

  # Internal response to cancel pending request (remote node is likely dead)
  class CancelResponse < Response; end
end
