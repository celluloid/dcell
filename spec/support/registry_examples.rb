shared_context "a DCell registry" do
  context "global registry" do
    before :each do
      subject.clear_globals
    end

    it "stores values" do
      subject.set_global("foobar", [1,2,3])
      subject.get_global("foobar").should == [1,2,3]
    end

    it "stores the keys of all globals" do
      subject.set_global("foobar", true)
      subject.global_keys.should include "foobar"
    end
  end
end
