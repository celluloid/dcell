RSpec.describe DCell::MessageHandler do
  it "properly handles incorrectly encoded incoming message" do
    expect {DCell::MessageHandler.decode_message ''}.to raise_error(DCell::MessageHandler::InvalidMessageError)
    expect {DCell::MessageHandler.handle_message ''}.not_to raise_error
  end

  it "properly handles improperly encoded messages and those that crash during dispatch" do
    ping = DCell::Message::Ping.new(nil).to_msgpack
    expect {DCell::MessageHandler.handle_message ping}.not_to raise_error

    invalid = {}.to_msgpack
    expect {DCell::MessageHandler.handle_message invalid}.not_to raise_error
  end
end
