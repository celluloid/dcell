require 'spec_helper'

describe DCell::Registry::MonetaAdapter do
  subject { DCell::Registry::MonetaAdapter.new :env => "test" }
  it_behaves_like "a DCell registry"
end
