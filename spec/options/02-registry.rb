TEST_ADEPTER = ENV['DCELL_TEST_ADAPTER'] || 'redis'

require "dcell/registries/#{TEST_ADEPTER}_adapter"
