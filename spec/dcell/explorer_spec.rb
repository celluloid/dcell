require 'dcell/explorer'

describe DCell::Explorer do
  EXPLORER_HOST = 'localhost'
  EXPLORER_PORT = 7778
  EXPLORER_BASE = "http://#{EXPLORER_HOST}:#{EXPLORER_PORT}"

  before :all do
    @explorer = DCell::Explorer.new(EXPLORER_HOST, EXPLORER_PORT)
  end

  it "reports the current node's status" do
    response = Net::HTTP.get URI(EXPLORER_BASE)
    response[%r{<a href="/nodes/(.*?)">}, 1].should == DCell.id
  end

  it "reports a given current node status" do
    response = Net::HTTP.get URI(EXPLORER_BASE + "/nodes/#{DCell.id}")
    response[%r{<a href="/nodes/(.*?)">}, 1].should == DCell.id
  end

  it "respond with 404 for non-existing node or paths" do
    response = Net::HTTP.get URI(EXPLORER_BASE + "/nodes/node")
    response.should == "Not found"
    response = Net::HTTP.get URI(EXPLORER_BASE + "/my.html")
    response.should == "Not found"
    response = Net::HTTP.get URI(EXPLORER_BASE + "/..")
    response.should == "Not found"
  end

  it "correctly return web resources" do
    response = Net::HTTP.get URI(EXPLORER_BASE + "/css/explorer.css")
    favicon = File.expand_path("../../../explorer/css/explorer.css", __FILE__)
    response.should == File.open(favicon, 'r').read
  end
end
