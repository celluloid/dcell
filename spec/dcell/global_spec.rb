describe DCell::Global do
  it "can handle unexisting keys" do
    expect { DCell::Global[:unexisting] }.to_not raise_exception
  end

  it "stores values" do
    DCell::Global[:the_answer] = 42
    DCell::Global[:the_answer].should == 42

    # Double check the global value is available on all nodes
    node = DCell::Node[TEST_NODE[:id]]
    node[:test_actor].the_answer.should == 42
  end

  it "stores the keys of all globals" do
    DCell::Global[:foo] = 1
    DCell::Global[:bar] = 2
    DCell::Global[:baz] = 3

    keys = DCell::Global.keys
    [:foo, :bar, :baz].each { |key| keys.should include key }
  end
end
