require 'dcell/registries/mongodb_adapter'

describe DCell::Registry::MongodbAdapter, :pending => TEST_ADEPTER != 'mongodb' && "no mongodb" do
  subject { DCell::Registry::MongodbAdapter.new TEST_DB[:mongodb] }
  it_behaves_like "a DCell registry"
end
