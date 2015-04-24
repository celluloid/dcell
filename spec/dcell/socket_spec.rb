RSpec.describe DCell::Socket do
  it "raises exception on invalid address configuration" do
    addr = 'tcp://127.0.1.0'
    expect {DCell::Socket::server addr, ''}.to raise_error(IOError)
    expect {DCell::Socket::client addr, ''}.to raise_error(IOError)
  end

  it "raises exception if address is already in use" do
    addr = 'tcp://127.0.0.1:1123'
    server = DCell::Socket::server addr, ''
    expect {DCell::Socket::server addr, ''}.to raise_error(IOError)
  end
end
