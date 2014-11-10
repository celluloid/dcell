require 'spec_helper'
require 'dcell/registries/mongodb_adapter'

describe DCell::Registry::MongodbAdapter, :pending => ENV["CI"] && "no mongodb" do
  subject { DCell::Registry::MongodbAdapter.new :db => 'dcell-test' }
  it_behaves_like "a DCell registry"
end
