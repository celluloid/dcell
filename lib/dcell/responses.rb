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
      mailbox = DCell::Router.find @address
      mailbox << self
    end
  end

  # Request successful
  class SuccessResponse < Response; end

  # Request failed
  class ErrorResponse < Response; end

  # Retry response (request to retry action)
  class RetryResponse < Response; end

  # Remote actor is dead
  class DeadActorResponse < Response; end
end
