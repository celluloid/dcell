require 'spec_helper'

describe DCell::RedisAdapter do
  subject { DCell::RedisAdapter.new :env => 'test' }
  it_behaves_like "a DCell registry"
end