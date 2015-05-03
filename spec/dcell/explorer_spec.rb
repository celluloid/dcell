require 'dcell/explorer'

RSpec.describe DCell::Explorer do
  EXPLORER_HOST = 'localhost'
  EXPLORER_PORT = 7778
  EXPLORER_BASE = "http://#{EXPLORER_HOST}:#{EXPLORER_PORT}"

  before :all do
    @explorer = DCell::Explorer.new(EXPLORER_HOST, EXPLORER_PORT)
  end

  it "reports the current node's status" do
    response = Net::HTTP.get URI(EXPLORER_BASE)
    expect(response[%r{<a href="/nodes/(.*?)">}, 1]).to eq(DCell.id)
  end

  it "reports a given current node status" do
    response = Net::HTTP.get URI(EXPLORER_BASE + "/nodes/#{DCell.id}")
    expect(response[%r{<a href="/nodes/(.*?)">}, 1]).to eq(DCell.id)
  end

  it "respond with 404 for non-existing node or paths" do
    response = Net::HTTP.get URI(EXPLORER_BASE + "/nodes/node")
    expect(response).to eq("Not found")
    response = Net::HTTP.get URI(EXPLORER_BASE + "/my.html")
    expect(response).to eq("Not found")
    response = Net::HTTP.get URI(EXPLORER_BASE + "/..")
    expect(response).to eq("Not found")
  end

  it "correctly return web resources" do
    response = Net::HTTP.get URI(EXPLORER_BASE + "/css/explorer.css")
    favicon = File.expand_path("../../../explorer/css/explorer.css", __FILE__)
    expect(response).to eq(File.open(favicon, 'r').read)
  end
end
