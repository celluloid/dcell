require 'spec_helper'

describe DCell::Registry::RedisAdapter do
  subject { DCell::Registry::RedisAdapter.new :env => 'test' }
  it_behaves_like "a DCell registry"
end