require 'spec_helper'

describe DCell::PullServer do
  it "raises exception on invalid address configuration" do
    DCellMock.setup :addr => 'tcp://127.0.1.0', :registry => {:adapter => 'dummy'}
    expect {DCell::PullServer.new DCellMock}.to raise_error(IOError)
  end

  it "raises exception if address is already in use" do
    DCellMock.setup :addr => 'tcp://127.0.0.1:1123', :registry => {:adapter => 'dummy'}
    server = DCell::PullServer.new DCellMock
    expect {DCell::PullServer.new DCellMock}.to raise_error(IOError)
  end

  it "properly handles incorrectly encoded incoming message" do
    DCellMock.setup :addr => 'tcp://127.0.0.1:*', :registry => {:adapter => 'dummy', :seed => ''}
    server = DCell::PullServer.new DCellMock, NullLogger

    expect {server.decode_message ''}.to raise_error(DCell::PullServer::InvalidMessageError, "couldn't determine message format: ")
    expect {server.handle_message ''}.not_to raise_error

    class Toto
      def marshal_load(args); raise; end
      def marshal_dump; []; end
    end
    expect {server.decode_message Marshal.dump(Toto.new)}.to raise_error(DCell::PullServer::InvalidMessageError, "invalid message: ")

    class Dodo
      def dispatch; raise; end
    end
    expect {server.handle_message Marshal.dump(Dodo.new)}.not_to raise_error

    server.close
  end
end
