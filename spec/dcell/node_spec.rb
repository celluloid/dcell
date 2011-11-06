require 'spec_helper'

describe DCell::Node do
  before do
    @node = DCell.me
    @node.id.should == DCell.id

    class JackieChan
      include Celluloid
      attr_reader :asses_kicked

      def initialize
        @asses_kicked = 42
      end

      def kick_ass
        @asses_kicked += 1
      end
    end

    JackieChan.supervise_as :drunken_master
  end

  it "looks up remote actors" do
    actor = @node[:drunken_master]
    actor.asses_kicked.should == 42
  end
end
