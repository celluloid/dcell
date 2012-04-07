require 'spec_helper'
require 'dcell/explorer'

describe DCell::Explorer do
  EXPLORER_HOST = 'localhost'
  EXPLORER_PORT = 7778
  EXPLORER_BASE = "http://#{EXPLORER_HOST}:#{EXPLORER_PORT}"

  before do
    @explorer = DCell::Explorer.new(EXPLORER_HOST, EXPLORER_PORT)
  end

  it "reports the current node's status" do
    response = Net::HTTP.get URI(EXPLORER_BASE)
    response[%r{<h1><.*?> ([\w\.\-]+)<\/h1>}, 1].should == DCell.id
  end
end
