TEST_ADEPTER = ENV['DCELL_TEST_ADAPTER'] || 'redis'

require "dcell/registries/#{TEST_ADEPTER}_adapter"

def test_db_options
  options = {}
  adapter = TEST_ADEPTER
  if adapter
    options[:registry] = {:adapter => adapter}
    options[:registry].merge! TEST_DB[adapter.to_sym]
  end
  options
end
